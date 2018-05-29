-- DROP FUNCTION udf_insert_commandlog(BatchKey VARCHAR(200),DBName VARCHAR(255),Command TEXT,CommandType VARCHAR(60));
CREATE OR REPLACE FUNCTION udf_insert_commandlog(
     BatchKey VARCHAR(200)
    ,DBName   VARCHAR(255)
    ,Command   TEXT
    ,CommandType VARCHAR(60)
) RETURNS INT 
        LANGUAGE plpgsql
        AS $$
DECLARE
    rcnt INT;
    newrowid INT;
    update_dt_time timestamp;
BEGIN
   
     -- capture date time
    update_dt_time := (SELECT current_timestamp);
    INSERT INTO public."CommandLog"
        (
         "BatchKey"
        ,"DBName"
        ,"Command"
        ,"CommandType"
        ,"StartTime"
        ,"CreatedDate"
        )
    SELECT   
         BatchKey
        ,DBName
        ,COALESCE(Command, '<EMPTY SQL>') as Command
        ,COALESCE(CommandType, 'SQL_COMMAND') as CommandType
        ,update_dt_time as "StartTime"
        ,update_dt_time as "CreatedDate"
    RETURNING "CommandLogID" INTO newrowid;

    raise notice 'Inserted Row ID : %',newrowid;
    raise notice 'Rows Updated or Inserted at: %', update_dt_time;

    RETURN newrowid;
END;
$$;

/*
    SELECT udf_insert_commandlog('123', 'test', 'SELECT CURRENT_TIMESTAMP;', 'SQL_COMMAND');
    SELECT * FROM "CommandLog" ORDER BY "CommandLogID" DESC LIMIT 10;

*/