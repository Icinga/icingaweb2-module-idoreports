CREATE OR REPLACE FUNCTION idoreports_get_sla_ok_percent(
	id INTEGER,
	starttime TIMESTAMP WITH TIME ZONE,
	endtime  TIMESTAMP WITH TIME ZONE,
	sla_id INTEGER DEFAULT NULL
) 
RETURNS float
LANGUAGE SQL
AS $$
--\set id 371
--\set starttime '2019-02-19 00:00:00'
--\set endtime '2019-02-20 10:00:00'
--\set sla_id null 

WITH crit AS (
	SELECT CASE objecttype_id
		WHEN 1 THEN 0
		WHEN 2 THEN 1
		END
	AS value
	FROM icinga_objects 
	WHERE object_id = id
),
before AS (
	-- low border, last event before the range we are looking for:
	SELECT down, state_time_ AS state_time,state FROM (
	(SELECT 1 AS prio
		,state > crit.value AS down
		,GREATEST(state_time,starttime) AS state_time_
		,state
	FROM icinga_statehistory,crit
	WHERE 
		object_id = id
	   AND	state_time < starttime
	   AND  state_type = 1
	ORDER BY state_time DESC
	LIMIT 1)
	UNION ALL
	(SELECT 2 AS prio
		,state > crit.value AS down
		,GREATEST(state_time,starttime) AS state_time_
		,state
	FROM icinga_statehistory,crit 
	WHERE 
		object_id = id
	   AND	state_time < starttime
	ORDER BY state_time DESC
	LIMIT 1)

	) ranked ORDER BY prio 
	LIMIT 1
),
all_hard_events AS (
	-- the actual range we're looking for:
	SELECT state > crit.value AS down
		,state_time
		,state
	FROM icinga_statehistory,crit
	WHERE 
		object_id = id
	AND	state_time >= starttime
	AND 	state_time <= endtime
	AND 	state_type = 1
),

after AS (
	-- the "younger" of the current host/service state and the first recorded event
	(SELECT state > crit_value AS down
		,LEAST(state_time,endtime) AS state_time
		,state
		
		 FROM (
		(SELECT state_time
			,state
			,crit.value crit_value
		FROM icinga_statehistory,crit
		WHERE 
			object_id = id
			AND	state_time > endtime
		AND     state_type = 1
		ORDER BY state_time ASC
		LIMIT 1)

		UNION ALL

		SELECT status_update_time
			,current_state
			,crit.value crit_value
		FROM icinga_hoststatus,crit
		WHERE host_object_id = id
		AND     state_type = 1

		UNION ALL

		SELECT status_update_time
			,current_state
			,crit.value crit_value
		FROM icinga_servicestatus,crit
		WHERE service_object_id = id
		AND   state_type = 1
	) AS after_searched_period 
	ORDER BY state_time ASC LIMIT 1)
)
, allevents AS (
	TABLE before 
	UNION ALL
	TABLE all_hard_events
	UNION ALL
	TABLE after
)
, downtimes AS (
	SELECT tstzrange(
			--GREATEST(actual_start_time, starttime)
			--, LEAST(actual_end_time, endtime)
			actual_start_time
		      , actual_end_time
		) AS downtime
	FROM icinga_downtimehistory
        WHERE object_id = id
	--          AND actual_start_time <= endtime
--          AND COALESCE(actual_end_time,starttime) >= starttime

	UNION ALL

	SELECT tstzrange(
			--GREATEST(start_time, starttime)
			--, LEAST(end_time, endtime)
			start_time
		      , end_time
		) AS downtime
	FROM icinga_outofsla_periods
        WHERE timeperiod_object_id = sla_id

)

--SELECT * FROM allevents;
, relevant AS (
	SELECT down
	,tstzrange(state_time, COALESCE(lead(state_time) OVER w, endtime),'(]') AS zeitraum
		--,lead(state_time) OVER w - state_time AS dauer
	FROM (
		SELECT state > crit.value AS down
		       , lead(state,1,state) OVER w > 1 AS next_down
		       , lag(state,1,state) OVER w > 1 AS prev_down
		       , state_time
		       , state
		FROM allevents,crit
		WINDOW w AS (ORDER BY state_time)
	) alle
	--WHERE down != next_down OR down != prev_down
	WINDOW w AS (ORDER BY state_time)
)
, relevant_down AS (
	SELECT *
		,zeitraum * downtime AS covered 
		,COALESCE(
			zeitraum - downtime
		       ,zeitraum
		) AS not_covered
	FROM relevant
	LEFT JOIN downtimes 
	  ON zeitraum && downtime
	WHERE down
) 
, effective_downtimes AS (
	SELECT not_covered
		, upper(not_covered) - lower(not_covered) AS dauer
	FROM relevant_down
)

--select * from effective_downtimes;

, final_result AS (
	SELECT sum(dauer) AS total_downtime
		, endtime - starttime AS considered
		, COALESCE(extract ('epoch' from sum(dauer)),0) AS down_secs
		, extract ('epoch' from endtime - starttime ) AS considered_secs
	FROM effective_downtimes
)

SELECT -- *,
 100.0 - down_secs / considered_secs * 100.0 AS availability
FROM final_result
;
$$;
