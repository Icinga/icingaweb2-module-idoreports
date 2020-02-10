\set id 1
\set start '2019-02-05 13:00'
\set end '2019-02-06 13:00'
\set sla_id null 

--'2019-02-19 00:00:00','2019-02-20 10:00:00'
--12347

WITH before AS (
	-- low border, last event before the range we are looking for:
	SELECT prio ,
		 state > 1 AS down, state_time_ AS state_time,state
		--,state_type, state_time
	       
	FROM (
	(SELECT 1 AS prio
		,state_time 
		,GREATEST(state_time,:'start') AS state_time_
		,state
		,state_type
	FROM icinga_statehistory 
	WHERE 
		object_id = :id
	   AND	state_time < :'start'
	   AND  state_type = 1
	ORDER BY state_time DESC
	LIMIT 1)
	UNION ALL
	(SELECT 2 AS prio
		,state_time 
		,GREATEST(state_time,:'start') AS state_time_
		,state
		,state_type
	FROM icinga_statehistory 
	WHERE 
		object_id = :id
	   AND	state_time < :'start'
	ORDER BY state_time DESC
	LIMIT 1)

	) ranked ORDER BY prio ASC 
	LIMIT 1
)  --SELECT * FROM before;
,all_hard_events AS (
	-- the actual range we're looking for:
	SELECT 5 prio, 
		state > 1 AS down
		,state_time
		,state
	FROM icinga_statehistory 
	WHERE 
		object_id = :id
	AND	state_time >= :'start'
	AND 	state_time <= :'end'
	AND 	state_type = 1
),

after AS (
	-- the "younger" of the current host/service state and the first recorded event
	SELECT prio, state > 1 AS down
		,LEAST(state_time,:'end') AS state_time
		,state
		
		 FROM (
		(SELECT 7 prio,
			state_time
			,state
		FROM icinga_statehistory 
		WHERE 
			object_id = :id
		AND	state_time > :'end'
		AND     state_type = 1
		ORDER BY state_time ASC
		LIMIT 1)

		UNION ALL

		SELECT 9 prio,
			status_update_time
			,current_state
		FROM icinga_hoststatus
		WHERE host_object_id = :id
		AND     state_type = 1

		UNION ALL

		SELECT 10 prio,
			status_update_time
			,current_state
		FROM icinga_servicestatus
		WHERE service_object_id = :id
		AND   state_type = 1
	) AS after_searched_period 
	ORDER BY state_time ASC LIMIT 1
) --SELECT * FROM after; 
, allevents AS (
	TABLE before 
	UNION ALL
	TABLE all_hard_events
	UNION ALL
	TABLE after
) --SELECT * FROM allevents; 
, downtimes AS (
	SELECT tstzrange(
			--GREATEST(actual_start_time, :'start')
		      --, LEAST(actual_end_time, :'end')
			actual_start_time
		      , actual_end_time
		) AS downtime
	FROM icinga_downtimehistory
        WHERE object_id = :id
--          AND actual_start_time <= :'end'
--          AND COALESCE(actual_end_time,:'start') >= :'start'

	UNION ALL

	SELECT tstzrange(
			--GREATEST(start_time, :'start')
		      --, LEAST(end_time, :'end')
			start_time
		      , end_time
		) AS downtime
	FROM icinga_outofsla_periods
        WHERE timeperiod_object_id = :sla_id

)

, relevant AS (
	SELECT down
	,tstzrange(state_time, COALESCE(lead(state_time) OVER w, :'end'),'(]') AS zeitraum
		--,lead(state_time) OVER w - state_time AS dauer
	FROM (
		SELECT state > 1 AS down
		       , lead(state,1,state) OVER w > 1 AS next_down
		       , lag(state,1,state) OVER w > 1 AS prev_down
		       , state_time
		       , state
		FROM allevents 
		WINDOW w AS (ORDER BY state_time)
	) alle
	WHERE down != next_down OR down != prev_down
	WINDOW w AS (ORDER BY state_time)
) --SELECT * FROM relevant;
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
) --SELECT * FROM relevant_down;

, effective_downtimes AS (
	SELECT not_covered
		, upper(not_covered) - lower(not_covered) AS dauer
	FROM relevant_down
) --SELECT * FROM effective_downtimes;

, final_result AS (
	SELECT sum(dauer) AS total_downtime
		, timestamptz :'end' - timestamptz :'start' AS considered
		, COALESCE(extract ('epoch' from sum(dauer)),0) AS down_secs
		, extract ('epoch' from timestamptz :'end' - timestamptz  :'start' ) AS considered_secs
	FROM effective_downtimes
) --SELECT * FROM final_result;

SELECT *
, 100.0 - down_secs / considered_secs * 100.0 AS availability
FROM final_result
;
