SELECT plan(7);
SELECT ok(idoreports_get_sla_ok_percent(1,'2019-02-05 12:00', '2019-02-05 14:00') = 0.0,'Host 1 was down 2 out of 2 hours');
SELECT ok(idoreports_get_sla_ok_percent(1,'2019-02-05 10:00', '2019-02-05 14:00') = 50.0,'Host 1 was down 2 out of 4 hours');
SELECT ok(idoreports_get_sla_ok_percent(1,'2019-02-05 10:00', '2019-02-05 18:00') = 75.0,'Host 1 was down 2 out of 8 hours');
SELECT ok(idoreports_get_sla_ok_percent(1,'2019-02-04 10:00', '2019-02-04 18:00') = 100.0,'Host 1 was not down before 02/05 12:00');
SELECT ok(idoreports_get_sla_ok_percent(1,'2019-02-06 10:00', '2019-02-08 18:00') = 100.0,'Host 1 was not down after 02/05 14:00');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-04 13:00', '2019-02-05 13:00')::text , '95.83333333333333','Host 1 was down for the last hour of checked timeframe');
SELECT is(idoreports_get_sla_ok_percent(1,'2019-02-05 13:00','2019-02-06 13:00' )::text , '95.83333333333333','Host 1 was down for the first hour of checked timeframe');
