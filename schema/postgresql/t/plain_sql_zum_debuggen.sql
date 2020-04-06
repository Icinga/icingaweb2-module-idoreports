--SELECT is(idoreports_get_sla_ok_percent(4,'2020-03-01 12:00', '2020-03-01 16:00')::float , 50.0::float,'Host 4 was considered down for 2 hours in a 4 hours time range starting with UP');
--SELECT is(idoreports_get_sla_ok_percent(5,'2020-04-01 12:00', '2020-04-01 16:00')::float , 50.0::float,'Host 5 was considered down for 2 hours in a 4 hours time range starting with DOWN');
\set id 5
\set start '2020-04-01 12:00'
\set end '2020-04-01 16:00'
\set sla_id null 

--'2019-02-19 00:00:00','2019-02-20 10:00:00'
--12347

WITH crit AS (
	SELECT CASE objecttype_id
		WHEN 1 THEN 0
		WHEN 2 THEN 1
		END
	AS value
	FROM icinga_objects 
	WHERE object_id = :id
),
before AS (
	-- low border, last event before the range we are looking for:
	SELECT down, state_time_ AS state_time,state FROM (
	(SELECT 1 AS prio
		,state > crit.value AS down
		,GREATEST(state_time,:'start') AS state_time_
		,state
	FROM icinga_statehistory,crit
	WHERE 
		object_id = :id
	   AND	state_time < :'start'
	   AND  state_type = 1
	ORDER BY state_time DESC
	LIMIT 1)
	UNION ALL
	(SELECT 2 AS prio
		,state > crit.value AS down
		,GREATEST(state_time,:'start') AS state_time_
		,state
	FROM icinga_statehistory,crit 
	WHERE 
		object_id = :id
	   AND	state_time < :'start'
	ORDER BY state_time DESC
	LIMIT 1)

	) ranked ORDER BY prio 
	LIMIT 1
)  SELECT * FROM before;
,all_hard_events AS (
	-- the actual range we're looking for:
	SELECT state > crit.value AS down
		,state_time
		,state
	FROM icinga_statehistory,crit
	WHERE 
		object_id = :id
	AND	state_time >= :'start'
	AND 	state_time <= :'end'
	AND 	state_type = 1
),

after AS (
	-- the "younger" of the current host/service state and the first recorded event
	(SELECT state > crit_value AS down
		,LEAST(state_time,:'end') AS state_time
		,state
		
		 FROM (
		(SELECT state_time
			,state
			,crit.value crit_value
		FROM icinga_statehistory,crit
		WHERE 
			object_id = :id
		AND	state_time > :'end'
		AND     state_type = 1
		ORDER BY state_time ASC
		LIMIT 1)

		UNION ALL

		SELECT status_update_time
			,current_state
			,crit.value crit_value
		FROM icinga_hoststatus,crit
		WHERE host_object_id = :id
		AND     state_type = 1

		UNION ALL

		SELECT status_update_time
			,current_state
			,crit.value crit_value
		FROM icinga_servicestatus,crit
		WHERE service_object_id = :id
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
) --SELECT * FROM allevents; 
, downtimes AS (
	SELECT tsrange(
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

	SELECT tsrange(
			--GREATEST(start_time, :'start')
		      --, LEAST(end_time, :'end')
			start_time
		      , end_time
		) AS downtime
	FROM icinga_outofsla_periods
        WHERE timeperiod_object_id = :sla_id

) --SELECT * FROM allevents;
, enriched AS (
	SELECT down
	,tsrange(state_time, COALESCE(lead(state_time) OVER w, :'end'),'(]') AS zeitraum
		--,lead(state_time) OVER w - state_time AS dauer
	FROM (
		SELECT state > crit.value AS down
		       , lead(state,1,state) OVER w > crit.value AS next_down
		       , lag(state,1,state) OVER w > crit.value AS prev_down
		       , state_time
		       , state
		FROM allevents,crit
		WINDOW w AS (ORDER BY state_time)
	) alle
	--WHERE down != next_down OR down != prev_down
	WINDOW w AS (ORDER BY state_time)
) 
, relevant AS (
    SELECT down 
    	,zeitraum * tsrange(:'start',:'end','(]') AS zeitraum
	FROM enriched 
    WHERE zeitraum && tsrange(:'start',:'end','(]')
) SELECT * FROM relevant;

, relevant_down AS (
	SELECT zeitraum 
		,down
		,zeitraum * downtime AS covered 
		,COALESCE(
			zeitraum - downtime
		       ,zeitraum
		) AS not_covered
	FROM relevant
	LEFT JOIN downtimes 
	  ON zeitraum && downtime
	WHERE down
) -- SELECT * FROM relevant_down;

, effective_downtimes AS (
	SELECT not_covered
		, upper(not_covered) - lower(not_covered) AS dauer
	FROM relevant_down
) --SELECT * FROM effective_downtimes;

, final_result AS (
	SELECT sum(dauer) AS total_downtime
		, timestamp :'end' - timestamp :'start' AS considered
		, COALESCE(extract ('epoch' from sum(dauer)),0) AS down_secs
		, extract ('epoch' from timestamp :'end' - timestamp  :'start' ) AS considered_secs
	FROM effective_downtimes
) --SELECT * FROM final_result;

SELECT :'start' AS starttime, :'end' AS endtime,*
, 100.0 - down_secs / considered_secs * 100.0 AS availability
FROM final_result
;
