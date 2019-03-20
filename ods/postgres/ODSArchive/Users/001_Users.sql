CREATE USER odsarchive_user_dev WITH ENCRYPTED PASSWORD '******' ;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT ALL ON TABLES TO odsarchive_user_dev;

GRANT ALL PRIVILEGES ON SCHEMA public TO odsarchive_user_dev;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO odsarchive_user_dev;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO odsarchive_user_dev;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO odsarchive_user_dev;
--GRANT ALL PRIVILEGES ON DATABASE "odsconfig_dev" TO odsarchive_user_dev;

ALTER DEFAULT PRIVILEGES IN SCHEMA arch
   GRANT ALL ON TABLES TO odsarchive_user_dev;

GRANT ALL PRIVILEGES ON SCHEMA arch TO odsarchive_user_dev;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA arch TO odsarchive_user_dev;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA arch TO odsarchive_user_dev;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA arch TO odsarchive_user_dev;
--GRANT ALL PRIVILEGES ON DATABASE "odsconfig_dev" TO odsarchive_user_dev;