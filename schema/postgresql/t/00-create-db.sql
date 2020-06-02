--create database icinga2;
CREATE EXTENSION IF NOT EXISTS pgtap;
SELECT plan(1);
SELECT is(count(*) , 1::bigint,'Extension pg_tap installed') FROM pg_extension WHERE extname = 'pgtap';
