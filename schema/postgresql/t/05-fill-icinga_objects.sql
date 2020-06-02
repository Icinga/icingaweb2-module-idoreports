-- Objects get a number and a type (1=host, 2=server)
SELECT plan(1);
INSERT INTO icinga_objects VALUES (1,1);
INSERT INTO icinga_objects VALUES (2,2);
INSERT INTO icinga_objects VALUES (3,1);
INSERT INTO icinga_objects VALUES (4,1);
INSERT INTO icinga_objects VALUES (5,1);
INSERT INTO icinga_objects VALUES (6,1);
SELECT is(count(*), 6::bigint, 'icinga_objects has correct # of rows') FROM icinga_objects;
