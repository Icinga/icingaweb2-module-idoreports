SELECT tap.plan(0);
CREATE TABLE IF NOT EXISTS icinga_outofsla_periods (
    timeperiod_object_id BIGINT(20) UNSIGNED NOT NULL,
    start_time timestamp NOT NULL,
    end_time timestamp NULL DEFAULT NULL
);
