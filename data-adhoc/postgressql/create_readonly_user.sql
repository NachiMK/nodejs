CREATE USER ods_user WITH ENCRYPTED PASSWORD 'H!xme_0ds_ah_dev1' ;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT ON TABLES TO ods_user;

GRANT CONNECT ON DATABASE plans_dev TO ods_user;
GRANT USAGE ON SCHEMA public TO ods_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ods_user;

-- GRANT CREATE TEMPORARY ALL PRIVILEGES ON DATABASE plans_dev TO ods_user;
