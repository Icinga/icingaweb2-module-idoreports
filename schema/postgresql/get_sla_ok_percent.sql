CREATE OR REPLACE FUNCTION idoreports_get_sla_ok_percent(
    id bigint,
    starttime timestamp with time zone,
    endtime timestamp with time zone,
    sla_id integer DEFAULT NULL
)
    RETURNS float
    LANGUAGE SQL
AS $$
--\set id 371
--\set starttime '2019-02-19 00:00:00'
--\set endtime '2019-02-20 10:00:00'
--\set sla_id null
WITH
    before AS (
        -- low border, last event before the range we are looking for:
        SELECT
            down,
            state_time,
            state
        FROM (
            (
                SELECT
                    1 AS prio,
                   state > 1 AS down,
                   GREATEST(state_time, starttime) AS state_time,
                   state
                FROM
                    icinga_statehistory
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
                    state > 1 AS down,
                    GREATEST(state_time, starttime) AS state_time,
                    state
                FROM
                    icinga_statehistory
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
            state > 1 AS down,
            state_time,
            state
        FROM
            icinga_statehistory
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
                state > 1 AS down,
                LEAST(state_time, endtime) AS state_time,
                state
            FROM (
                (
                    SELECT
                        state_time,
                        state
                    FROM
                        icinga_statehistory
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
                        current_state
                    FROM
                        icinga_hoststatus
                    WHERE
                        host_object_id = id
                        AND state_type = 1
                )
                UNION ALL
                (
                    SELECT
                        status_update_time,
                        current_state
                    FROM
                        icinga_servicestatus
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
                tstzrange(
--                     GREATEST(actual_start_time, starttime), LEAST(actual_end_time, endtime)
                    actual_start_time, actual_end_time
                ) AS downtime
            FROM
                icinga_downtimehistory
            WHERE
              object_id = id
--               AND actual_start_time <= endtime
--               AND COALESCE(actual_end_time, starttime) >= starttime
        )
        UNION ALL
        (
            SELECT
                tstzrange(
--                     GREATEST(start_time, starttime), LEAST(end_time, endtime)
                    start_time, end_time
                ) AS downtime
            FROM
                icinga_outofsla_periods
            WHERE
                timeperiod_object_id = sla_id
        )
    ),

    relevant AS (
        --SELECT * FROM allevents;
        SELECT
            down,
            tstzrange(state_time, COALESCE(lead(state_time) OVER w, endtime),'(]') AS timerange
--             ,lead(state_time) OVER w - state_time AS duration
        FROM (
            SELECT
                state > 1 AS down,
                lag(state) OVER w > 1 AS next_down,
                state_time,
                state
            FROM
                allevents
            WINDOW
                w AS (ORDER BY state_time)
         ) alle
        WHERE
            down != next_down
        WINDOW
            w AS (ORDER BY state_time)
    ),

    relevant_down AS (
        SELECT
            *,
            timerange * downtime AS covered,
            COALESCE(timerange - downtime, timerange) AS not_covered
        FROM
            relevant
        LEFT JOIN downtimes ON timerange && downtime
        WHERE
            down
    ),

    effective_downtimes AS (
        SELECT
            not_covered,
            upper(not_covered) - lower(not_covered) AS duration
        FROM
            relevant_down
    )

--SELECT * FROM effective_downtimes;
SELECT
    100.0 - EXTRACT('epoch' FROM SUM(duration)) / EXTRACT('epoch' FROM endtime - starttime ) * 100.0 AS availability
FROM
    effective_downtimes;
$$;
