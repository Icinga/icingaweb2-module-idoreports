SELECT tap.plan(0);
CREATE TABLE IF NOT EXISTS icinga_downtimehistory (
    object_id bigint unsigned default 0,
    entry_time timestamp NULL,
    scheduled_start_time timestamp NULL,
    scheduled_end_time timestamp NULL,
    was_started smallint default 0,
    actual_start_time timestamp NULL,
    actual_end_time timestamp NULL
);
