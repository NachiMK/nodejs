CREATE ROLE odsddb_role;

CREATE USER odsddb_user WITH ENCRYPTED PASSWORD 'H!xme_ddb_ah_dev1' ;

GRANT odsdbb_role TO odsddb_user, hixme_root;

ALTER DEFAULT PRIVILEGES IN SCHEMA raw
   GRANT ALL ON TABLES TO odsddb_role;

GRANT ALL PRIVILEGES ON SCHEMA raw TO odsddb_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA raw TO odsddb_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA raw TO odsddb_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA raw TO odsddb_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA stg
   GRANT ALL ON TABLES TO odsddb_role;

GRANT ALL PRIVILEGES ON SCHEMA stg TO odsddb_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA stg TO odsddb_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA stg TO odsddb_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA stg TO odsddb_role;

GRANT ALL PRIVILEGES ON DATABASE "odsdynamodb_dev" TO odsddb_role;

