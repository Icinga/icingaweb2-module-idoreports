DROP FUNCTION IF EXISTS idoreports_get_sla_ok_percent;

DELIMITER //

CREATE FUNCTION idoreports_get_sla_ok_percent (
  id BIGINT UNSIGNED,
  start DATETIME,
  end DATETIME,
  sla_timeperiod_object_id BIGINT UNSIGNED
) RETURNS DECIMAL(7, 4)
  READS SQL DATA
BEGIN
  DECLARE result DECIMAL(7, 4);

  -- We use user-defined @-vars, this allows for easier sub-queries testing
  SET
    -- First, set our parameters:
    @id = id,
    @start = start,
    @end = end,
    @sla_timeperiod_object_id = sla_timeperiod_object_id,

    -- Then fetch our object type id:
    @type_id = (SELECT objecttype_id FROM icinga_objects WHERE object_id = id),

    -- Next, reset inline vars:
    @next_type = NULL,
    @last_ts = NULL,
    @last_type = NULL,
    @add_duration = 0,
    @last_state = NULL,
    @cnt_tp = null,
    @cnt_dt = NULL,

    -- And finally reset all eventual result variables:
    @sla_ok_seconds = NULL,
    @sla_ok_percent = NULL,
    @problem_seconds = NULL,
    @problem_percent = NULL,
    @problem_in_downtime_seconds = NULL,
    @problem_in_downtime_percent = NULL,
    @total_seconds = NULL
  ;


  IF @type_id NOT IN (1, 2) THEN
    RETURN NULL;
  END IF;

SELECT CASE WHEN @last_state IS NULL THEN NULL ELSE sla_ok_percent END INTO result FROM (
SELECT
  @sla_ok_seconds := SUM(
    CASE
      WHEN in_downtime + out_of_slatime > 0 THEN 1
      WHEN is_problem THEN 0
      ELSE 1
    END * duration)
  ) AS sla_ok_seconds,
  @sla_ok_percent := CAST(100 * SUM(
    CASE
      WHEN in_downtime + out_of_slatime > 0 THEN 1
      WHEN is_problem THEN 0
      ELSE 1
    END * duration / (UNIX_TIMESTAMP(@end) - UNIX_TIMESTAMP(@start))
  ) AS DECIMAL(7, 4)) AS sla_ok_percent,
  @problem_seconds := SUM(is_problem * duration) AS problem_seconds,
  @problem_percent := CAST(
    SUM(is_problem * duration) / SUM(duration) * 100 AS DECIMAL(7, 4)
  ) AS problem_percent,
  @problem_in_downtime_seconds := SUM(
    is_problem * in_downtime * duration
  ) AS problem_in_downtime_seconds,
  @problem_in_downtime_percent := CAST(100 * SUM(
    is_problem * in_downtime * duration
    / (UNIX_TIMESTAMP(@end) - UNIX_TIMESTAMP(@start))
  ) AS DECIMAL(7, 4)) AS problem_in_downtime_percent,
  @total_seconds := SUM(duration) AS total_time
FROM (
  -- ----------------------------------------------------------------- --
-- SLA relevant events, re-modelled with duration                    --
--                                                                   --
-- This declares and clears the following variables:                 --
-- * @last_state                                       --
-- * @add_duration --
-- * @next_type --
-- * @cnt_dt --
-- * @cnt_tp --
-- * @type_id                    --
-- * @next_type --
-- * @start (used)                   --
--                                                                   --
-- Columns:                                                          --
-- ***                               --
-- ----------------------------------------------------------------- --

SELECT
  state_time,
  UNIX_TIMESTAMP(state_time),
  CAST(COALESCE(@last_ts, UNIX_TIMESTAMP(@start)) AS UNSIGNED),
  CAST(UNIX_TIMESTAMP(state_time)
       - CAST(COALESCE(@last_ts, UNIX_TIMESTAMP(@start)) AS UNSIGNED)
       + CAST(COALESCE(@add_duration, 0) AS UNSIGNED) AS UNSIGNED) AS duration,

  -- @add_duration is used as long as we haven't seen a state
  @add_duration AS add_duration,

  @next_type AS current_type,
  @next_type := type AS next_type,

  -- current_state is the state from the last state change until now:
  @last_state AS current_state,

  CASE WHEN @last_state IS NULL THEN NULL ELSE
    CASE WHEN @type_id = 1
      THEN CASE WHEN @last_state > 0 THEN 1 ELSE 0 END
    ELSE CASE WHEN @last_state > 1 THEN 1 ELSE 0 END
    END
  END AS is_problem,

  CASE WHEN COALESCE(@cnt_dt, 0) > 0 THEN 1 ELSE 0 END AS in_downtime,
  CASE WHEN COALESCE(@cnt_tp, 0) > 0 THEN 1 ELSE 0 END AS out_of_slatime,

  COALESCE(@cnt_dt, 0) AS dt_depth,
  COALESCE(@cnt_tp, 0) AS tp_depth,

  CASE type
  WHEN 'dt_start' THEN @cnt_dt := COALESCE(@cnt_dt, 0) + 1
  WHEN 'dt_end' THEN @cnt_dt := GREATEST(@cnt_dt - 1, 0)
  ELSE COALESCE(@cnt_dt, 0)
  END AS next_dt_depth,

  CASE type
  WHEN 'sla_end' THEN @cnt_tp := COALESCE(@cnt_tp, 0) + 1
  WHEN 'sla_start' THEN @cnt_tp := GREATEST(@cnt_tp - 1, 0)
  ELSE COALESCE(@cnt_tp, 0)
  END AS next_tp_depth,

  -- next_state is the state from now on, so it replaces @last_state:
  CASE
  -- Set our next @last_state if we have a hard state change
  WHEN type IN ('hard_state', 'former_state', 'current_state') THEN @last_state := state
  -- ...or if there is a soft_state and no @last_state has been seen before
  WHEN type = 'soft_state' THEN
    -- If we don't have a @last_state...
    CASE WHEN @last_state IS NULL
      -- ...use and set our own last_hard_state (last_state is the inner query alias)...
      THEN @last_state := last_state
    -- ...and return @last_state otherwise, as soft states shall have no
    -- impact on availability
    ELSE @last_state END

  WHEN type IN ('dt_start', 'sla_end') THEN @last_state
  WHEN type IN ('dt_end', 'sla_start') THEN @last_state
  END AS next_state,

  -- Our start_time is either the last end_time or @start...
  @last_ts AS start_time,

  -- ...end when setting the new end_time we remember it in @last_ts:
  CASE
  WHEN type = 'fake_end' THEN state_time
  ELSE @last_ts := UNIX_TIMESTAMP(state_time)
  END AS end_time

FROM (
-- ----------------------------------------------------------------- --
-- SLA relevant events                                               --
--                                                                   --
-- Variables:                                                        --
-- * @id     The IDO object_id                                       --
-- * @start  Start of the chosen time period. Currently DATE, should --
--           be UNIX_TIMESTAMP                                       --
-- * @end    Related end of the chosen time period                   --
-- * @sla_timeperiod_object_id  Time period object ID in case SLA    --
--           times should be respected                               --
--                                                                   --
-- Columns:                                                          --
-- state_time, type, state, last_state                               --
-- ----------------------------------------------------------------- --

-- START fetching statehistory events
SELECT
  state_time,
  CASE state_type WHEN 1 THEN 'hard_state' ELSE 'soft_state' END AS type,
  state,
  -- Workaround for a nasty Icinga issue. In case a hard state is reached
  -- before max_check_attempts, the last_hard_state value is wrong. As of
  -- this we are stepping through all single events, even soft ones. Of
  -- course soft states do not have an influence on the availability:
  CASE state_type WHEN 1 THEN last_state ELSE last_hard_state END AS last_state
FROM icinga_statehistory
WHERE object_id = @id
  AND state_time >= @start
  AND state_time <= @end
-- STOP fetching statehistory events

-- START fetching last state BEFORE the given interval as an event
UNION SELECT * FROM (
  SELECT
    @start AS state_time,
    'former_state' AS type,
    CASE state_type WHEN 1 THEN state ELSE last_hard_state END AS state,
    CASE state_type WHEN 1 THEN last_state ELSE last_hard_state END AS last_state
  FROM icinga_statehistory h
  WHERE object_id = @id
    AND state_time < @start
  ORDER BY h.state_time DESC
  LIMIT 1
) formerstate
-- END fetching last state BEFORE the given interval as an event

-- START ADDING a fake end
UNION SELECT
  @end AS state_time,
  'fake_end' AS type,
  NULL AS state,
  NULL AS last_state
FROM DUAL
-- END ADDING a fake end

-- START fetching current host state as an event
-- TODO: This is not 100% correct. state should be fine, last_state sometimes isn't.
UNION SELECT
  GREATEST(
    @start,
    CASE state_type WHEN 1 THEN last_state_change ELSE last_hard_state_change END
  ) AS state_time,
  'current_state' AS type,
  CASE state_type WHEN 1 THEN current_state ELSE last_hard_state END AS state,
  last_hard_state AS last_state
FROM icinga_hoststatus
WHERE CASE state_type WHEN 1 THEN last_state_change ELSE last_hard_state_change END < @start
  AND host_object_id = @id
  AND CASE state_type WHEN 1 THEN last_state_change ELSE last_hard_state_change END <= @end
  AND status_update_time > @start
-- END fetching current host state as an event

-- START fetching current service state as an event
-- ++ , only if older than @start
UNION SELECT
  GREATEST(
    @start,
    CASE state_type WHEN 1 THEN last_state_change ELSE last_hard_state_change END
  ) AS state_time,
  'current_state' AS type,
  CASE state_type WHEN 1 THEN current_state ELSE last_hard_state END AS state,
  last_hard_state AS last_state
FROM icinga_servicestatus
WHERE CASE state_type WHEN 1 THEN last_state_change ELSE last_hard_state_change END < @start
  AND service_object_id = @id
  -- AND CASE state_type WHEN 1 THEN last_state_change ELSE last_hard_state_change END <= @end
  AND status_update_time > @start
-- END fetching current service state as an event

-- START adding add all related downtime start times
-- TODO: Handling downtimes still being active would be nice.
--       But pay attention: they could be completely outdated
UNION SELECT
  GREATEST(actual_start_time, @start) AS state_time,
  'dt_start' AS type,
  NULL AS state,
  NULL AS last_state
FROM icinga_downtimehistory
WHERE object_id = @id
  AND actual_start_time < @end
  AND actual_end_time > @start
-- STOP adding add all related downtime start times

-- START adding add all related downtime end times
UNION SELECT
  LEAST(actual_end_time, @end) AS state_time,
  'dt_end' AS type,
  NULL AS state,
  NULL AS last_state
FROM icinga_downtimehistory
WHERE object_id = @id
  AND actual_start_time < @end
  AND actual_end_time > @start
-- STOP adding add all related downtime end times

-- START fetching SLA time period start times ---
UNION ALL
SELECT
  start_time AS state_time,
  'sla_start' AS type,
  NULL AS state,
  NULL AS last_state
FROM icinga_outofsla_periods
WHERE timeperiod_object_id = @sla_timeperiod_object_id
  AND start_time >= @start
  AND start_time <= @end
-- STOP fetching SLA time period start times ---

-- START fetching SLA time period end times ---
UNION ALL SELECT
  end_time AS state_time,
  'sla_end' AS type,
  NULL AS state,
  NULL AS last_state
 FROM icinga_outofsla_periods
WHERE timeperiod_object_id = @sla_timeperiod_object_id
  AND end_time >= @start
  AND end_time <= @end
-- STOP fetching SLA time period end times ---

ORDER BY state_time ASC,
  CASE type
  -- Order is important. current_state and former_state
  -- are potential candidates for the initial state of the chosen period.
  -- the last one wins, and preferably we have a state change before the
  -- chosen period. Otherwise we assume that the first state change after
  -- that period knows about the former state. Last fallback is the
  WHEN 'current_state' THEN 0
  WHEN 'former_state' THEN 2
  WHEN 'soft_state' THEN 3
  WHEN 'hard_state' THEN 4
  WHEN 'sla_end' THEN 5
  WHEN 'sla_start' THEN 6
  WHEN 'dt_start' THEN 7
  WHEN 'dt_end' THEN 8
  ELSE 9
  END ASC

) events

) intervals

) sladetails;

  RETURN result;
END//

DELIMITER ;
