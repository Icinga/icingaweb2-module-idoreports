SELECT tap.plan(1);
INSERT INTO icinga_servicestatus (service_object_id, status_update_time, current_state, last_state_change, last_hard_state_change, last_hard_state, state_type) VALUES (2, '2019-02-10 12:00:00', 0, NULL, NULL, 0, 1);
INSERT INTO icinga_servicestatus (service_object_id, status_update_time, current_state, last_state_change, last_hard_state_change, last_hard_state, state_type) VALUES (2, '2019-03-10 15:00:00', 2, '2019-03-05 11:00:00', '2019-03-05 12:00:00', 0, 1);
SELECT tap.eq(count(*), 2, 'icinga_servicestatus has 2 rows') FROM icinga_servicestatus;
