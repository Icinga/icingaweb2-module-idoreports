Tests for the idoreports_get_sla_ok_percent() function
======================================================

These are pg_tap tests. You need pg_tap installed for the PG version you want to test on, e.g. "postgresql-12-pgtap" for Debian/Ubuntu. 

I used these to find the cause for some seamingly strange NULL results.
Which were basically due to a badly chosen ALIAS ("state_time" on line 20, which is now "state_time_").

I run these tests on an Ubuntu/Debian system with "pg_virtualenv" like this:

```
pg_virtualenv -s pg_prove t/0*.sql
```
or simply
```
t/testme.sh
```

