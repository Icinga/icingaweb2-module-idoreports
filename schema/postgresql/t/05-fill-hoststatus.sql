SELECT plan(1);
COPY icinga_hoststatus FROM STDIN;
1	2019-02-10 12:00:00+01	0	1
1	2019-03-10 15:00:00+01	1	1
3	2019-03-10 16:15:00+01	1	1
\.

SELECT is(count(*), 3::bigint, 'icinga_hoststatus has 3 rows') FROM icinga_hoststatus;
