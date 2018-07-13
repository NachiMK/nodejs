DROP FUNCTION IF EXISTS ods."udf_GetDataPipeLineTaskQueueStatus"(INT);
CREATE OR REPLACE FUNCTION ods."udf_GetDataPipeLineTaskQueueStatus"(DataPipeLineTaskQueueId INT) 
RETURNS 
    VARCHAR(40) AS $$
DECLARE
    retValue VARCHAR(40);
BEGIN
    IF DataPipeLineTaskQueueId <= 0 THEN
        RAISE EXCEPTION 'DataPipeLineTaskQueueId Cannot be null or less than zero, DataPipeLineTaskQueueId: --> %'
            , DataPipeLineTaskQueueId
            USING HINT = 'Please check your parameter';
    END IF;

    -- First setup Attributes for my task before querying it.
    RAISE NOTICE 'DataPipeLineTaskQueueId to get Status, DataPipeLineTaskQueueId: --> %'
    , DataPipeLineTaskQueueId;

    SELECT  T."TaskStatusDesc" AS "TaskStatus"
    INTO    retValue
    FROM    ods."DataPipeLineTaskQueue"     AS Q
    INNER
    JOIN    ods."TaskStatus"                AS T    ON T."TaskStatusId" = Q."TaskStatusId"
    WHERE   Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId;
    
    -- Result
    RETURN retValue;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetDataPipeLineTaskQueueStatus"(3);
*/
