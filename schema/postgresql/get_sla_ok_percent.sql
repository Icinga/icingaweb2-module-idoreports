create or replace function range_exclude(
    anyelement,
    anyelement
) returns anyarray
as
$$
declare
    r1 text;
    r2 text;
begin
    -- Check input parameters
    if not pg_typeof($1) in ('numrange'::regtype, 'int8range'::regtype, 'daterange'::regtype, 'tsrange'::regtype,
                             'tstzrange'::regtype) then
        raise exception 'Function accepts only range types but got % type.', pg_typeof($1);
    end if;

    if $2 is null then return array [$1]; end if;

    -- If result is single element
    if ($1 &< $2 or $1 &> $2) then return array [$1 - $2]; end if;

    -- Else build array of two intervals
    if lower_inc($1) then r1 := '['; else r1 := '('; end if;
    r1 := r1 || lower($1) || ',' || lower($2);
    if lower_inc($2) then r1 := r1 || ')'; else r1 := r1 || ']'; end if;

    if upper_inc($2) then r2 := '('; else r2 := '['; end if;
    r2 := r2 || upper($2) || ',' || upper($1);
    if upper_inc($1) then r2 := r2 || ']'; else r2 := r2 || ')'; end if;
    return array [r1, r2];
end
$$
    immutable language plpgsql;

DROP FUNCTION IF EXISTS idoreports_get_sla_ok_percent(BIGINT, TIMESTAMPTZ, TIMESTAMPTZ, INT);

CREATE OR REPLACE FUNCTION idoreports_get_sla_ok_percent(
    id        BIGINT,
    starttime TIMESTAMP WITHOUT TIME ZONE,
    endtime   TIMESTAMP WITHOUT TIME ZONE,
    sla_id    INTEGER DEFAULT NULL
) RETURNS float
    LANGUAGE SQL
AS
$$

WITH
    crit AS (
        SELECT
            CASE objecttype_id
                WHEN 1 THEN 0
                WHEN 2 THEN 1
            END AS value
        FROM
            icinga_objects
        WHERE
            object_id = id
    ),
    before AS (
        -- low border, last event before the range we are looking for:
        SELECT
            down,
            state_time_ AS state_time,
            state
        FROM
            (
                (
                    SELECT
                        1 AS prio,
                        state > crit.value AS down,
                        GREATEST(state_time, starttime) AS state_time_,
                        state
                    FROM
                        icinga_statehistory,
                        crit
                    WHERE
                        object_id = id
                        AND state_time < starttime
                        AND state_type = 1
                    ORDER BY
                        state_time DESC
                    LIMIT 1
                )
                UNION ALL
                (
                    SELECT
                        2 AS prio,
                        state > crit.value AS down,
                        GREATEST(state_time, starttime) AS state_time_,
                        state
                    FROM
                        icinga_statehistory,
                        crit
                    WHERE
                        object_id = id
                        AND state_time < starttime
                    ORDER BY
                        state_time DESC
                    LIMIT 1
                )
            ) ranked
        ORDER BY
            prio
        LIMIT 1
    ),
    all_hard_events AS (
        -- the actual range we're looking for:
        SELECT
            state > crit.value AS down,
            state_time,
            state
        FROM
            icinga_statehistory,
            crit
        WHERE
            object_id = id
            AND state_time >= starttime
            AND state_time <= endtime
            AND state_type = 1
    ),
    after AS (
        -- the "younger" of the current host/service state and the first recorded event
        (
            SELECT
                state > crit_value AS down,
                LEAST(state_time, endtime) AS state_time,
                state

            FROM
                (
                    (
                        SELECT
                            state_time,
                            state,
                            crit.value AS crit_value
                        FROM
                            icinga_statehistory,
                            crit
                        WHERE
                            object_id = id
                            AND state_time > endtime
                            AND state_type = 1
                        ORDER BY
                            state_time
                        LIMIT 1
                    )
                    UNION ALL
                    (
                        SELECT
                            status_update_time,
                            current_state,
                            crit.value AS crit_value
                        FROM
                            icinga_hoststatus,
                            crit
                        WHERE
                            host_object_id = id
                            AND state_type = 1
                    )
                    UNION ALL
                    (
                        SELECT
                            status_update_time,
                            current_state,
                            crit.value AS crit_value
                        FROM
                            icinga_servicestatus,
                            crit
                        WHERE
                            service_object_id = id
                            AND state_type = 1
                    )
                ) AS after_searched_period
            ORDER BY
                state_time
            LIMIT 1
        )
    ),
    allevents AS (
        TABLE before
        UNION ALL
        TABLE all_hard_events
        UNION ALL
        TABLE after
    ),
    downtimes AS (
        (
            SELECT
                tsrange(actual_start_time, actual_end_time) AS downtime
            FROM
                icinga_downtimehistory
            WHERE
                object_id = id
        )
        UNION ALL
        (
            SELECT
                tsrange(start_time, end_time) AS downtime
            FROM
                icinga_outofsla_periods
            WHERE
                timeperiod_object_id = sla_id
        )
    ),
    enriched AS (
        SELECT
            down,
            tsrange(state_time, COALESCE(lead(state_time) OVER w, endtime), '(]') AS timeframe
            --,lead(state_time) OVER w - state_time AS dauer
        FROM
            (
                SELECT
                    state > crit.value AS down,
                    lead(state, 1, state) OVER w > crit.value AS next_down,
                    lag(state, 1, state) OVER w > crit.value AS prev_down,
                    state_time,
                    state
                FROM
                    allevents,
                    crit WINDOW w AS (ORDER BY state_time)
            ) alle WINDOW w AS (ORDER BY state_time)
    ),
    relevant AS (
        SELECT
            down,
            timeframe * tsrange(starttime, endtime, '(]') AS timeframe
        FROM
            enriched
        WHERE
            timeframe && tsrange(starttime, endtime, '(]')
    ),
    relevant_down AS (
        SELECT *,
            timeframe * downtime AS covered,
            unnest(range_exclude(timeframe, downtime)) AS not_covered
        FROM
            relevant
                LEFT JOIN downtimes ON timeframe && downtime
        WHERE
            down
    ),
    effective_downtimes AS (
        SELECT
            not_covered,
            upper(not_covered) - lower(not_covered) AS dauer
        FROM
            relevant_down
    ),
    final_result AS (
        SELECT
            sum(dauer) AS total_downtime,
            endtime - starttime AS considered,
            COALESCE(extract('epoch' from sum(dauer)), 0) AS down_secs,
            extract('epoch' from endtime - starttime) AS considered_secs
        FROM
            effective_downtimes
    )

SELECT
    100.0 - down_secs / considered_secs * 100.0 AS availability
FROM
    final_result ;
$$;
