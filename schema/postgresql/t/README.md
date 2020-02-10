Tests for the idoreports_get_sla_ok_percent() function
======================================================

These are pg_tap tests. You need pg_tap installed for the PG version you want to test on, e.g. "postgresql-12-pgtap" for Debian/Ubuntu. 

I used these to find the cause for some seamingly strange NULL results.
Which were basically due to a badly chosen ALIAS ("state_time" on line 20, which is now "state_time_").

I run these tests on an Ubuntu/Debian system with "pg_virtualenv" like this:

```
pg_virtualenv pg_prove t/0*.sql
```

N.B.: They deliberately fail! The only relevant part is "07-test-func.sql", which obviously should _not_ fail. 
Having an overall fail allows to look into the db by simply adding "-s" to the pg_virtualenv call above.
