Tests for the idoreports_get_sla_ok_percent() function
======================================================

These are myTAP tests. You need myTAP installed.

These tests can be run with "my_virtualenv", "mytap" and "my_prove" like this:

```
my_virtualenv bash -c 'pushd ~/path/to/mytap; ./install.sh -t; mysql -e "CREATE DATABASE icinga"; popd; my_prove -D icinga t/0*.sql
```

N.B.: They deliberately fail (also, t/06-get_sla_ok_percent.sql is just a
symlink to the "real thing", so adding a tap.plan() call would break stuff)!

The only relevant part is "07-test-func.sql", which obviously should _not_
fail. 

Having an overall fail allows to look into the db by simply adding "-s" to the
my_virtualenv call above.
