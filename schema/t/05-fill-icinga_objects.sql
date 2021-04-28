SELECT tap.plan(1);
INSERT INTO icinga_objects(object_id, objecttype_id) VALUES (1,1);
INSERT INTO icinga_objects(object_id, objecttype_id) VALUES (2,2);
SELECT tap.eq(count(*), 2, 'icinga_objects has 2 rows') FROM icinga_objects;
