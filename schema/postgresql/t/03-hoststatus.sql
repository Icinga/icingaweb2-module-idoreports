SELECT plan(0);
CREATE TABLE icinga_hoststatus (
    host_object_id numeric DEFAULT '0'::numeric,
    status_update_time timestamp with time zone,
    current_state smallint DEFAULT '0'::smallint,
    state_type smallint DEFAULT '0'::smallint
);
