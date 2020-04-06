#!/bin/sh
pg_virtualenv -s pg_prove $(dirname $0)/0*.sql
