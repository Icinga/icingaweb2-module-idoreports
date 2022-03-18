-- Objects get a number and a type (1=host, 2=server)
SELECT plan(1);
INSERT INTO icinga_downtimehistory (object_id,actual_start_time,actual_end_time) VALUES (7,'2019-04-15 11:45:00','2019-04-15 11:50:00');
INSERT INTO icinga_downtimehistory (object_id,actual_start_time,actual_end_time) VALUES (7,'2019-04-15 12:00:00','2019-04-15 12:05:00');
SELECT is(count(*), 2::bigint, 'icinga_downtimehistory has correct # of rows') FROM icinga_downtimehistory;
