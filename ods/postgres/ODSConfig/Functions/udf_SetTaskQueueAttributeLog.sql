DROP FUNCTION IF EXISTS ods."udf_SetTaskQueueAttributeLog"(INT, INT);
CREATE OR REPLACE FUNCTION ods."udf_SetTaskQueueAttributeLog"(DataPipeLineTaskQueueId INT, PrevTaskId INT default null) 
RETURNS 
    VOID AS $$
DECLARE
    -- retRecord ods."TaskQueueAttributeLog"%rowtype;
    ParentTaskId INT;
    RootTaskId INT;
BEGIN
    
    IF DataPipeLineTaskQueueId is null THEN
        RAISE EXCEPTION 'DataPipeLineTaskQueueId Cannot be NULL, DataPipeLineTaskQueueId: --> %', DataPipeLineTaskQueueId
            USING HINT = 'Please check your DataPipeLineTaskQueueId parameter';
    END IF;

    IF PrevTaskId IS NULL OR (PrevTaskId <= 0) THEN
        SELECT  CAST("AttributeValue" AS INT)
        INTO    PrevTaskId
        FROM    ods."TaskQueueAttributeLog"
        WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
        AND     "AttributeName" = 'PreviousTaskId';
    END IF;

    IF PrevTaskId IS NULL THEN
        RAISE EXCEPTION 'PreviousTaskId Cannot be NULL, PreviousTaskId: --> %', PrevTaskId
            USING HINT = 'Please check your PreviousTaskId parameter or Make sure it was inserted in the Create udf_createDataPipeLine_ProcessHistory Function';
    END IF;

    SELECT  "ParentTaskId"
    INTO    ParentTaskId
    FROM    ods."DataPipeLineTaskQueue"
    WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId;

    RAISE NOTICE ' udf_setTaskQueueAttributeLog, TaskId: %, Prev. Task Id: %, Parent: %'
    , DataPipeLineTaskQueueId, PrevTaskId, ParentTaskId;

    -- Find the Root ID
    SELECT  ods."udf.GetRootTaskId"(DataPipeLineTaskQueueId)
    INTO    RootTaskId;

    RootTaskId := COALESCE(RootTaskId, ParentTaskId, -9999);

    WITH MyAttributes
    AS
    (
        -- set my task attributes
        SELECT   "DataPipeLineTaskQueueId"
                ,"AttributeName"
                ,"AttributeValue"
        FROM    ods."udf_GetMyTaskAttributes"(DataPipeLineTaskQueueId, RootTaskId, ParentTaskId)

        UNION ALL

        -- Copy down Attributes from
        -- my previous task or my Parent Task that I am interested in
        SELECT   "DataPipeLineTaskQueueId"
                ,"AttributeName"
                ,"AttributeValue"
        FROM    ods."udf_GetMyParentPreviousTaskAttributes"(DataPipeLineTaskQueueId, PrevTaskId, ParentTaskId)

        UNION ALL
        SELECT   "DataPipeLineTaskQueueId"
                ,"AttributeName"
                ,"AttributeValue"
        FROM    ods."udf_GetMyParentPreviousTaskAttributes"(DataPipeLineTaskQueueId, PrevTaskId, ParentTaskId)

        UNION ALL

        SELECT   "DataPipeLineTaskQueueId"
                ,"AttributeName"
                ,"AttributeValue"
        FROM    ods."udf_GetSpecialAttributes"(DataPipeLineTaskQueueId, ParentTaskId)
    )
    INSERT  INTO ods."TaskQueueAttributeLog" AS A
    (
        "DataPipeLineTaskQueueId"
        ,"AttributeName"
        ,"AttributeValue"
    )
    SELECT  DISTINCT 
            "DataPipeLineTaskQueueId"
            ,"AttributeName"
            ,"AttributeValue"
    FROM    MyAttributes
    ON  CONFLICT ON CONSTRAINT UNQ_TaskQueueAttributeLog
    DO  UPDATE
        SET "AttributeValue" = EXCLUDED."AttributeValue"
            ,"UpdatedDtTm" = CURRENT_TIMESTAMP
        WHERE A."AttributeValue" != EXCLUDED."AttributeValue";

END;
$$ LANGUAGE plpgsql;

/*
    SELECT * FROM ods."udf_SetTaskQueueAttributeLog"(1);
*/