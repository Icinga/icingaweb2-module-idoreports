SELECT plan(0);
CREATE TABLE icinga_servicestatus (
    service_object_id numeric DEFAULT '0'::numeric,
    status_update_time timestamp WITHOUT time zone,
    current_state smallint DEFAULT '0'::smallint,
    state_type smallint DEFAULT '0'::smallint
);
