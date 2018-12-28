ALTER DEFAULT PRIVILEGES IN SCHEMA arch
   GRANT ALL ON TABLES TO odsarchive_user;

GRANT ALL PRIVILEGES ON SCHEMA arch TO odsarchive_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA arch TO odsarchive_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA arch TO odsarchive_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA arch TO odsarchive_user;
GRANT ALL PRIVILEGES ON DATABASE "odsarchive_dev" TO odsarchive_user;