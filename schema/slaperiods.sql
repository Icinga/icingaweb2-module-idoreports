DROP TABLE IF EXISTS icinga_sla_periods;
CREATE TABLE icinga_sla_periods (
  timeperiod_object_id BIGINT(20) UNSIGNED NOT NULL,
  start_time timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  end_time timestamp NULL DEFAULT NULL,
  PRIMARY KEY tp_start (timeperiod_object_id, start_time),
  UNIQUE KEY tp_end (timeperiod_object_id, end_time)
) ENGINE InnoDB;

DROP TABLE IF EXISTS icinga_outofsla_periods;
CREATE TABLE icinga_outofsla_periods (
  timeperiod_object_id BIGINT(20) UNSIGNED NOT NULL,
  start_time timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  end_time timestamp NULL DEFAULT NULL,
  PRIMARY KEY tp_start (timeperiod_object_id, start_time),
  UNIQUE KEY tp_end (timeperiod_object_id, end_time)
) ENGINE InnoDB;
