SELECT plan(1);
INSERT INTO icinga_objects VALUES (1,1);
INSERT INTO icinga_objects VALUES (2,2);
SELECT is(count(*), 2::bigint, 'icinga_objects has 2 rows') FROM icinga_objects;
