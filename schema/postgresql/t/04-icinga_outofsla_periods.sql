SELECT plan(0);
CREATE TABLE icinga_outofsla_periods (
    timeperiod_object_id numeric NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL
);
