SELECT tablename, 'DROP TABLE IF EXISTS "' || tablename || '";' FROM pg_catalog.pg_tables where lower(tablename) like '%plan%_bak%'
order by tablename;

SELECT tablename, 'DROP TABLE IF EXISTS "' || tablename || '";' FROM pg_catalog.pg_tables where lower(tablename) like '%stage%'
order by tablename;

SELECT tablename, 'DROP TABLE IF EXISTS "' || tablename || '";' FROM pg_catalog.pg_tables where lower(tablename) like '%stg%'
order by tablename;


DROP TABLE IF EXISTS "stage_plans_av_raw_nv_rp423_20180419";
DROP TABLE IF EXISTS "stage_planservicearea_test_20180411";
