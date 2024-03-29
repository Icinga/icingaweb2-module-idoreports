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
    covered AS (
        SELECT 
               upper(covered_by_downtime) - lower(covered_by_downtime) AS dauer
        FROM (
          SELECT
              timeframe * downtime AS covered_by_downtime
          FROM
              relevant
                  LEFT JOIN downtimes ON timeframe && downtime
          WHERE
              down
       ) AS foo
    ),
    relevant_down AS (
        SELECT *,
            upper(timeframe) - lower(timeframe) AS dauer
        FROM
            relevant
        WHERE
            down
    ),
    final_result AS (
        SELECT
            sum(dauer) - (
		SELECT sum(dauer) FROM covered
	    ) AS total_downtime,
            endtime - starttime AS considered,
            COALESCE(extract('epoch' from sum(dauer)), 0) AS down_secs,
            extract('epoch' from endtime - starttime) AS considered_secs
        FROM
            relevant_down
    )

SELECT
    100.0 - down_secs / considered_secs * 100.0 AS availability
FROM
    final_result ;
$$;
