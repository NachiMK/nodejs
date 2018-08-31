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
    startTime TIMESTAMP;
    retRecord ods."DataPipeLineTaskQueue"%rowtype;
BEGIN
    SELECT   "TaskStatusId"
            ,CASE WHEN TaskStatus IN ('History Captured', 'Completed', 'Error') 
                  THEN CURRENT_TIMESTAMP ELSE NULL END as "endTime"
            ,CASE WHEN TaskStatus IN ('Processing', 'Re-Process') 
                  THEN CURRENT_TIMESTAMP ELSE NULL END as "startTime"
    INTO    taskStatusId, endTime, startTime
    FROM   ods."TaskStatus" 
    WHERE  "TaskStatusDesc" = TaskStatus;

    ErrorJson := CAST(TaskError as jsonb);

    IF taskStatusId IS NOT NULL THEN
        -- UPDATE Parent AS WELL
        -- If a Child Process Errors then make sure parent is also in same status
        UPDATE  ods."DataPipeLineTaskQueue" AS Parent
        SET     "TaskStatusId"  = taskStatusId
                ,"UpdatedDtTm"  = CURRENT_TIMESTAMP
        FROM    ods."DataPipeLineTaskQueue" AS  DQ
        INNER
        JOIN    ods."TaskStatus"            AS  TS      ON  TS."TaskStatusId" = taskStatusId
        WHERE   DQ."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
        AND     Parent."DataPipeLineTaskQueueId" = DQ."ParentTaskId"
        AND     TS."TaskStatusDesc" IN ('Error')
        AND     TS."TaskStatusId" != Parent."TaskStatusId";

        UPDATE  ods."DataPipeLineTaskQueue" AS DQ
        SET     "TaskStatusId"  = taskStatusId
                ,"StartDtTm"    = CASE WHEN TS."TaskStatusDesc" NOT IN ('Processing', 'Re-Process') 
                                       THEN startTime ELSE DQ."StartDtTm" END
                ,"EndDtTm"      = endTime
                ,"Error"        = ErrorJson
                ,"UpdatedDtTm"  = CURRENT_TIMESTAMP
        FROM    ods."TaskStatus"    AS  TS
        WHERE   DQ."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
        AND     TS."TaskStatusId" = DQ."TaskStatusId";

        -- IF Child is complete
        -- and if this is the last child
        -- then mark the parent as complete
        -- as well.
        UPDATE  ods."DataPipeLineTaskQueue" AS Parent
        SET     "TaskStatusId"  = taskStatusId
                ,"EndDtTm"      = endTime
                ,"UpdatedDtTm"  = CURRENT_TIMESTAMP
        FROM    ods."DataPipeLineTaskQueue" AS  DQ
        INNER
        JOIN    ods."TaskStatus"            AS  TS      ON  TS."TaskStatusId" = taskStatusId
        WHERE   DQ."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
        AND     Parent."DataPipeLineTaskQueueId" = DQ."ParentTaskId"
        AND     TS."TaskStatusDesc" IN ('Completed')
        AND     NOT EXISTS 
                (
                    SELECT 1
                    FROM    ods."DataPipeLineTaskQueue" as OC
                    WHERE   OC."ParentTaskId"  = DQ."ParentTaskId"
                    AND     OC."RunSequence"   > DQ."RunSequence"
                );
    END IF;

    IF SaveStatus IS NOT NULL THEN
        INSERT INTO ods."TaskQueueAttributeLog" AS A
                (
                     "DataPipeLineTaskQueueId"
                    ,"AttributeName"
                    ,"AttributeValue"
                )
        SELECT  DataPipeLineTaskQueueId, "key" as "AttributeName", REPLACE(CAST("value" AS VARCHAR(500)), '"', '') as "AttributeValue"
        FROM    jsonb_each(SaveStatus::jsonb)
        ON  CONFLICT ON CONSTRAINT UNQ_TaskQueueAttributeLog
        DO  UPDATE
            SET "AttributeValue" = EXCLUDED."AttributeValue"
                ,"UpdatedDtTm" = CURRENT_TIMESTAMP
            WHERE A."AttributeValue" != EXCLUDED."AttributeValue";
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

    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(36, 'Completed', null, '{"EndTime":"06/27/2018 21:01:14.998",
"KeyName":"dynamodb/clients/1-clients-Data-_20180627_210114920.json",
"RowCount":"1",
"StartTime":"06/27/2018 21:01:14.919",
"tableName":"clients",
"S3DataFile":"https://s3-us-west-2.amazonaws.com/dev-ods-data/dynamodb/clients/1-clients-Data-_20180627_210114920.json",
"S3BucketName":"dev-ods-data"}');

    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(1, 'Error', '{"test":"value"}');
    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(1, 'unkn', '{"test":"value"}');
    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(1, 'History Captured', null);

    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(3, 'Processing');
    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(3, 'Error');
    SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(8, 'Completed');

    SELECT * FROM ods."DataPipeLineTaskQueue" WHERE "DataPipeLineTaskQueueId" = 1;

    SELECT * FROM ods."TaskStatus"

    psql -h localhost -d odsconfig_dev -U Nachi -c "SELECT * FROM ods.\"udf_UpdateDataPipeLineTaskQueueStatus\"(1, 'Completed', null);"
*/