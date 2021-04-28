-- CREATE DATABASE icinga;
USE tap;

SELECT tap.plan(1);
SELECT tap.has_table('tap', '__tresults__', 'MyTap is installed');
