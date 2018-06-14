DROP FUNCTION IF EXISTS ods."udf_UpdateDataPipeLineTaskQueueStatus"(int, character varying, text);
DROP FUNCTION IF EXISTS ods."udf_UpdateDataPipeLineTaskQueueStatus"(int, character varying, text, jsonb);
CREATE OR REPLACE FUNCTION ods."udf_UpdateDataPipeLineTaskQueueStatus"(DataPipeLineTaskQueueId INT
                                                                    , TaskStatus VARCHAR(40)
                                                                    , TaskError TEXT default NULL
                                                                    , SaveStatus jsonb default NULL) 
RETURNS 
    SETOF ods."DataPipeLineTaskQueue" AS $$
DECLARE
    taskStatusId INT;
    ErrorJson jsonb;
    endTime TIMESTAMP;
    retRecord ods."DataPipeLineTaskQueue"%rowtype;
BEGIN
    SELECT   "TaskStatusId"
            ,CASE WHEN TaskStatus IN ('History Captured', 'Completed', 'Error') 
                  THEN CURRENT_TIMESTAMP ELSE NULL END as "endTime"
    INTO    taskStatusId, endTime
    FROM   ods."TaskStatus" 
    WHERE  "TaskStatusDesc" = TaskStatus;

    ErrorJson := CAST(TaskError as jsonb);

    IF taskStatusId IS NOT NULL THEN
        UPDATE  ods."DataPipeLineTaskQueue" AS DQ
        SET     "TaskStatusId"  = taskStatusId
                ,"EndDtTm"      = endTime
                ,"Error"        = ErrorJson
                ,"UpdatedDtTm"  = CURRENT_TIMESTAMP
        WHERE   DQ."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId;
    END IF;

    IF SaveStatus IS NOT NULL THEN
        INSERT INTO ods."TaskQueueAttributeLog"
                (
                     "DataPipeLineTaskQueueId"
                    ,"AttributeName"
                    ,"AttributeValue"
                )
        SELECT  DataPipeLineTaskQueueId, "key" as "AttributeName", "value" as "AttributeValue"
        FROM    jsonb_each(SaveStatus::jsonb);
    END IF;

    -- Result
    FOR retRecord in 
        SELECT  *
        FROM    ods."DataPipeLineTaskQueue"
        WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
    LOOP
        return next retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    -- Code to test and verify
    SELECT * FROM ods."DataPipeLineTaskQueue" WHERE "DataPipeLineTaskQueueId" = 1;

    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(1, 'Completed', '{"test":"value"}');
    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(1, 'Error', '{"test":"value"}');
    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(1, 'unkn', '{"test":"value"}');
    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(1, 'History Captured', null);

    SELECT * FROM ods."DataPipeLineTaskQueue" WHERE "DataPipeLineTaskQueueId" = 1;

    SELECT * FROM ods."TaskStatus"

    psql -h localhost -d odsconfig_dev -U Nachi -c "SELECT * FROM ods.\"udf_UpdateDataPipeLineTaskQueueStatus\"(1, 'Completed', null);"
*/