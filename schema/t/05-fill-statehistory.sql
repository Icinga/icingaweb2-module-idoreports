SELECT tap.plan(1);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-01 00:00:00', 1, 0, 1, 0, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-05 11:00:00', 1, 3, 0, 0, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-05 12:00:00', 1, 3, 1, 3, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-05 13:00:00', 1, 0, 0, 3, 3);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-05 14:00:00', 1, 0, 1, 0, 3);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-03-01 00:00:00', 1, 0, 1, 0, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-03-05 11:00:00', 1, 3, 0, 0, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-03-05 12:00:00', 1, 3, 1, 3, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-01 00:00:00', 2, 0, 1, 0, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-05 11:00:00', 2, 3, 0, 0, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-05 12:00:00', 2, 3, 1, 3, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-05 13:00:00', 2, 0, 0, 3, 3);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-02-05 14:00:00', 2, 0, 1, 0, 3);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-03-01 00:00:00', 2, 0, 1, 0, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-03-05 11:00:00', 2, 3, 0, 0, 0);
INSERT INTO icinga_statehistory(state_time, object_id, state, state_type, last_state, last_hard_state) VALUES('2019-03-05 12:00:00', 2, 3, 1, 3, 0);

SELECT tap.eq(count(*), 16, 'icinga_statehistory has 16 rows') FROM icinga_statehistory;
