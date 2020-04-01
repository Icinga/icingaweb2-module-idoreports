SELECT plan(1);
COPY icinga_hoststatus FROM STDIN;
1	2019-02-10 12:00:00+01	0	1
1	2019-03-10 15:00:00+01	1	1
3	2019-03-10 16:15:00+01	1	1
4	2020-03-01 00:00:00+01	1	1
5	2020-04-01 00:00:00+01	0	1
\.

SELECT is(count(*), 5::bigint, 'icinga_hoststatus has 5 rows') FROM icinga_hoststatus;
