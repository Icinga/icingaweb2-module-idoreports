SELECT plan(24);
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-05 12:00', '2019-02-05 14:00')::float , 0.0::float,'Host 1 was down 2 out of 2 hours');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-05 10:00', '2019-02-05 14:00')::float , 50.0::float,'Host 1 was down 2 out of 4 hours');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-05 10:00', '2019-02-05 18:00')::float , 75.0::float,'Host 1 was down 2 out of 8 hours');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-04 10:00', '2019-02-04 18:00')::float , 100.0::float,'Host 1 was not down before 02/05 12:00');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-06 10:00', '2019-02-08 18:00')::float , 100.0::float,'Host 1 was not down after 02/05 14:00');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-04 13:00', '2019-02-05 13:00')::float , 95.83333333333333::float,'Host 1 was down for the last hour of checked timeframe');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-05 13:00', '2019-02-06 13:00')::float , 95.83333333333333::float,'Host 1 was down for the first hour of checked timeframe');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-03-05 11:00', '2019-03-05 13:00')::float , 50.0::float,'Host 1 was down 1 out of 2 hours');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-03-05 12:00', '2019-03-05 13:00')::float , 0.0::float,'Host 1 was down during that period');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-03-05 13:00', '2019-03-05 14:00')::float , 0.0::float,'Host 1 was down during that period');

SELECT is(idoreports_get_sla_ok_percent(2,'2019-02-05 12:00', '2019-02-05 14:00')::float , 0.0::float,'Service 2 was down 2 out of 2 hours');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-02-05 10:00', '2019-02-05 14:00')::float , 50.0::float,'Service 2 was down 2 out of 4 hours');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-02-05 10:00', '2019-02-05 18:00')::float , 75.0::float,'Service 2 was down 2 out of 8 hours');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-02-04 10:00', '2019-02-04 18:00')::float , 100.0::float,'Service 2 was not down before 02/05 12:00');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-02-06 10:00', '2019-02-08 18:00')::float , 100.0::float,'Service 2 was not down after 02/05 14:00');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-02-04 13:00', '2019-02-05 13:00')::float , 95.83333333333333::float,'Service 2 was down for the last hour of checked timeframe');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-02-05 13:00', '2019-02-06 13:00')::float , 95.83333333333333::float,'Service 2 was down for the first hour of checked timeframe');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-03-05 11:00', '2019-03-05 13:00')::float , 50.0::float,'Service 2 was down 1 out of 2 hours');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-03-05 12:00', '2019-03-05 13:00')::float , 0.0::float,'Service 2 was down during that period');
SELECT is(idoreports_get_sla_ok_percent(2,'2019-03-05 13:00', '2019-03-05 14:00')::float , 0.0::float,'Service 2 was down during that period');

SELECT is(idoreports_get_sla_ok_percent(3,'2019-03-10 17:00', '2019-03-11 00:00')::float , 0.0::float,'Host 3 was considered down for the rest of the day');

SELECT is(idoreports_get_sla_ok_percent(4,'2020-03-01 12:00', '2020-03-01 16:00')::float , 50.0::float,'Host 4 was considered down for 2 hours in a 4 hours time range starting with UP');
SELECT is(idoreports_get_sla_ok_percent(5,'2020-04-01 12:00', '2020-04-01 16:00')::float , 50.0::float,'Host 5 was considered down for 2 hours in a 4 hours time range starting with DOWN');

SELECT is(idoreports_get_sla_ok_percent(6,'2019-04-01 11:43:16','2019-04-01 15:43:16')::float , 46.65972222222222::float,'Host 4 was down untile recently');
