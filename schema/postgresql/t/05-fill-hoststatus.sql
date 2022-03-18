-- Rows are: hostid,timestamp, status (0 up, 1 down), state_type (always use 1)
SELECT plan(1);
COPY icinga_hoststatus FROM STDIN;
1	2019-02-10 12:00:00+01	0	1
1	2019-03-10 15:00:00+01	1	1
3	2019-03-10 16:15:00+01	1	1
4	2020-03-01 00:00:00+01	1	1
5	2020-04-01 14:00:00+01	0	1
6	2019-04-01 13:51:17+01	0	1
7	2019-04-14 11:00:00+01	0	1
7	2019-04-15 11:00:00+01	1	1
7	2019-04-15 12:52:00+01	0	1
7	2019-04-15 12:55:00+01	1	1
7	2019-04-15 12:57:00+01	0	1
\.

SELECT is(count(*), 11::bigint, 'icinga_hoststatus has correct # of rows') FROM icinga_hoststatus;
