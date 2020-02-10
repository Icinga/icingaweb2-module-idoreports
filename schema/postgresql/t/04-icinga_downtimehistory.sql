CREATE TABLE icinga_downtimehistory (
    object_id numeric DEFAULT '0'::numeric,
    entry_time timestamp with time zone,
    scheduled_start_time timestamp with time zone,
    scheduled_end_time timestamp with time zone,
    was_started smallint DEFAULT '0'::smallint,
    actual_start_time timestamp with time zone,
    actual_end_time timestamp with time zone
);
