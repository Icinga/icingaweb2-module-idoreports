CREATE TABLE icinga_statehistory (
    state_time timestamp with time zone,
    object_id numeric DEFAULT '0'::numeric,
    state smallint DEFAULT '0'::smallint,
    state_type smallint DEFAULT '0'::smallint
);
