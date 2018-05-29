-- DROP FUNCTION udf_update_commandlog_endtime(commandLogID INT);
CREATE OR REPLACE FUNCTION udf_update_commandlog_endtime(
     commandLogID INT
) RETURNS VOID 
        LANGUAGE plpgsql
        AS $$
DECLARE
    update_dt_time timestamp;
BEGIN
   
     -- capture date time
    update_dt_time := (SELECT current_timestamp);

    UPDATE  public."CommandLog"
    SET     "EndTime" = update_dt_time
    WHERE   "CommandLogID" = commandLogID
    AND     "EndTime" IS NULL;

    raise notice 'Row Updated : %',commandLogID;
    raise notice 'Rows Updated at: %', update_dt_time;

END;
$$;

/*
    SELECT udf_update_commandlog_endtime(1);
    SELECT * FROM "CommandLog" ORDER BY "EndtTime" DESC LIMIT 10;

*/