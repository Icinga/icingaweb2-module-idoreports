SELECT tap.plan(20);
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-02-05 12:00', '2019-02-05 14:00', NULL) , 0.0000,'Host 1 was down 2 out of 2 hours');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-02-05 10:00', '2019-02-05 14:00', NULL) , 50.0000,'Host 1 was down 2 out of 4 hours');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-02-05 10:00', '2019-02-05 18:00', NULL) , 75.0000,'Host 1 was down 2 out of 8 hours');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-02-04 10:00', '2019-02-04 18:00', NULL) , 100.0000,'Host 1 was not down before 02/05 12:00');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-02-06 10:00', '2019-02-08 18:00', NULL) , 100.0000,'Host 1 was not down after 02/05 14:00');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-02-04 13:00', '2019-02-05 13:00', NULL) , 95.8333,'Host 1 was down for the last hour of checked timeframe');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-02-05 13:00', '2019-02-06 13:00', NULL) , 95.8333,'Host 1 was down for the first hour of checked timeframe');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-03-05 11:00', '2019-03-05 13:00', NULL) , 50.0000,'Host 1 was down 1 out of 2 hours');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-03-05 12:00', '2019-03-05 13:00', NULL) , 0.0000,'Host 1 was down during that period');
SELECT tap.eq(idoreports_get_sla_ok_percent(1,'2019-03-05 13:00', '2019-03-05 14:00', NULL) , 0.0000,'Host 1 was down during that period');

SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-02-05 12:00', '2019-02-05 14:00', NULL) , 0.0000,'Service 2 was down 2 out of 2 hours');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-02-05 10:00', '2019-02-05 14:00', NULL) , 50.0000,'Service 2 was down 2 out of 4 hours');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-02-05 10:00', '2019-02-05 18:00', NULL) , 75.0000,'Service 2 was down 2 out of 8 hours');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-02-04 10:00', '2019-02-04 18:00', NULL) , 100.0000,'Service 2 was not down before 02/05 12:00');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-02-06 10:00', '2019-02-08 18:00', NULL) , 100.0000,'Service 2 was not down after 02/05 14:00');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-02-04 13:00', '2019-02-05 13:00', NULL) , 95.8333,'Service 2 was down for the last hour of checked timeframe');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-02-05 13:00', '2019-02-06 13:00', NULL) , 95.8333,'Service 2 was down for the first hour of checked timeframe');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-03-05 11:00', '2019-03-05 13:00', NULL) , 50.0000,'Service 2 was down 1 out of 2 hours');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-03-05 12:00', '2019-03-05 13:00', NULL) , 0.0000,'Service 2 was down during that period');
SELECT tap.eq(idoreports_get_sla_ok_percent(2,'2019-03-05 13:00', '2019-03-05 14:00', NULL) , 0.0000,'Service 2 was down during that period');