SELECT tap.plan(0);
CREATE TABLE IF NOT EXISTS icinga_servicestatus (
    service_object_id bigint unsigned default 0,
    status_update_time timestamp NULL,
    current_state smallint default 0,
    last_state_change timestamp NULL,
    last_hard_state_change timestamp NULL,
    last_hard_state smallint default 0,
    state_type smallint default 0
);
