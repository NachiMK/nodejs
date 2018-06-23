ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT ALL ON TABLES TO apilog_user;

GRANT ALL PRIVILEGES ON SCHEMA public TO apilog_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO apilog_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO apilog_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO apilog_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA log
   GRANT ALL ON TABLES TO apilog_user;

GRANT ALL PRIVILEGES ON SCHEMA log TO apilog_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA log TO apilog_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA log TO apilog_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA log TO apilog_user;
