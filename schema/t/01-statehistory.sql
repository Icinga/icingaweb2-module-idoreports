SELECT tap.plan(0);
CREATE TABLE IF NOT EXISTS icinga_statehistory (
    state_time timestamp NULL,
    object_id bigint unsigned default 0,
    state smallint default 0,
    state_type smallint default 0,
    last_state smallint default 0,
    last_hard_state smallint default 0
);
