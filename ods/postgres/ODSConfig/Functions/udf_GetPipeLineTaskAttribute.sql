DROP FUNCTION IF EXISTS ods."udf_GetPipeLineTaskQueueAttribute"(INT);
DROP FUNCTION IF EXISTS ods."udf_GetPipeLineTaskQueueAttribute"(INT, BOOLEAN);
CREATE OR REPLACE FUNCTION ods."udf_GetPipeLineTaskQueueAttribute"(DataPipeLineTaskQueueId INT, UpdateAttributes BOOLEAN default false) 
RETURNS 
    SETOF ods."TaskQueueAttributeLog" AS $$
DECLARE
    retRecord ods."TaskQueueAttributeLog"%rowtype;
BEGIN
    IF DataPipeLineTaskQueueId <= 0 THEN
        RAISE EXCEPTION 'DataPipeLineTaskQueueId Cannot be null or less than zero, DataPipeLineTaskQueueId: --> %, TableName: --> %'
            , DataPipeLineTaskQueueId, TableName
            USING HINT = 'Please check your parameter';
    END IF;

    -- First setup Attributes for my task before querying it.
    RAISE NOTICE 'DataPipeLineTaskQueueId Atrributes Update Options, DataPipeLineTaskQueueId: --> %, Update Attributes --> %'
    , DataPipeLineTaskQueueId
    , COALESCE(UpdateAttributes, true);
    
    IF COALESCE(UpdateAttributes, true) = true THEN
        PERFORM  1
        FROM    ods."DataPipeLineTaskQueue" AS Q,
        LATERAL ods."udf_SetTaskQueueAttributeLog"(Q."DataPipeLineTaskQueueId", null)  t
        WHERE   Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId;
    END IF;

    -- Result
    FOR retRecord in 
        SELECT   "TaskQueueAttributeLogId"
                ,"DataPipeLineTaskQueueId"
                ,"AttributeName"
                ,"AttributeValue"
                ,"CreatedDtTm"
                ,"UpdatedDtTm"
        FROM    ods."TaskQueueAttributeLog" AS TAL
        WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
    LOOP
        RETURN NEXT retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetPipeLineTaskQueueAttribute"(2, null);
*/
