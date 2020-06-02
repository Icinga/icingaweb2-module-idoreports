SELECT plan(1);
COPY icinga_servicestatus FROM STDIN;
2	2019-02-10 12:00:00+01	0	1
2	2019-03-10 15:00:00+01	2	1
\.
SELECT is(count(*), 2::bigint, 'icinga_servicestatus has 2 rows') FROM icinga_servicestatus;

