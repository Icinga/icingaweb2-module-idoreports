SELECT plan(1);
\i get_sla_ok_percent.sql
SELECT is(COUNT(*),1::bigint) FROM pg_catalog.pg_proc WHERE proname = 'idoreports_get_sla_ok_percent';
