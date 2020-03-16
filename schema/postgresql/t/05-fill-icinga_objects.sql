SELECT plan(1);
INSERT INTO icinga_objects VALUES (1,1);
INSERT INTO icinga_objects VALUES (2,2);
INSERT INTO icinga_objects VALUES (3,1);
SELECT is(count(*), 3::bigint, 'icinga_objects has 3 rows') FROM icinga_objects;
