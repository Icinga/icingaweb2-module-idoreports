SELECT plan(0);
CREATE TABLE icinga_downtimehistory (
    object_id numeric DEFAULT '0'::numeric,
    entry_time timestamp WITHOUT time zone,
    scheduled_start_time timestamp WITHOUT time zone,
    scheduled_end_time timestamp WITHOUT time zone,
    was_started smallint DEFAULT '0'::smallint,
    actual_start_time timestamp WITHOUT time zone,
    actual_end_time timestamp WITHOUT time zone
);
