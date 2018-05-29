-- DROP TABLE IF EXISTS "CommandLog";
CREATE TABLE IF NOT EXISTS public."CommandLog"(
     "CommandLogID"  SERIAL      NOT NULL PRIMARY KEY
    ,"BatchKey"      VARCHAR(200)    NOT NULL
    ,"DBName"        VARCHAR(255)    NOT NULL
    ,"Command"       TEXT        NOT NULL
    ,"CommandType"   VARCHAR(60) NOT NULL
    ,"StartTime"     TIMESTAMP   NOT NULL
    ,"EndTime"       TIMESTAMP   NULL
    ,"ErrorMessage"  TEXT        NULL
    ,"CreatedDate"   TIMESTAMP   NOT  NULL DEFAULT CURRENT_TIMESTAMP
);