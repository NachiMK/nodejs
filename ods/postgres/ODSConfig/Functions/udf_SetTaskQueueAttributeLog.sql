DROP FUNCTION IF EXISTS ods."udf_SetTaskQueueAttributeLog"(INT, INT);
CREATE OR REPLACE FUNCTION ods."udf_SetTaskQueueAttributeLog"(DataPipeLineTaskQueueId INT, PrevTaskId INT default null) 
RETURNS 
    VOID AS $$
DECLARE
    -- retRecord ods."TaskQueueAttributeLog"%rowtype;
    ParentTaskId INT;
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

    WITH MyAttributes
    AS
    (
        -- set my task attributes
        SELECT   Q."DataPipeLineTaskQueueId"
                ,A."AttributeName"
                ,CASE WHEN TA."AttributeValue" LIKE '%{Id}%' 
                    THEN REPLACE(TA."AttributeValue"
                                ,'{Id}'
                                ,(
                                    CAST(PrevTaskId AS VARCHAR(10)) || '-' ||
                                    CAST(DataPipeLineTaskQueueId AS VARCHAR(10)) || '-' || 
                                    CAST("DataPipeLineTaskQueueId" AS VARCHAR)
                                )
                                )
                    ELSE TA."AttributeValue"
                END AS "AttributeValue"
        FROM    ods."DataPipeLineTaskQueue" AS Q
        INNER
        JOIN    ods."DataPipeLineTask"      AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
        INNER
        JOIN    ods."TaskAttribute"         AS TA   ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
        INNER
        JOIN    ods."Attribute"             AS  A   ON  A."AttributeId" = TA."AttributeId"
        WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId) -- OR Q."ParentTaskId" = DataPipeLineTaskQueueId

        UNION ALL

        -- Copy down Attributes from
        -- my previous task or my Parent Task that I am interested in
        SELECT   Q."DataPipeLineTaskQueueId"
                ,A."AttributeName"
                ,L."AttributeValue"
        FROM    ods."DataPipeLineTaskQueue"     AS Q
        INNER
        JOIN    ods."DataPipeLineTask"          AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
        INNER
        JOIN    ods."DataPipeLineTaskConfig"    AS DPC  ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
        INNER
        JOIN    ods."TaskConfigAttribute"       AS  TA  ON  TA."DataPipeLineTaskConfigId" = DPC."DataPipeLineTaskConfigId"
        INNER
        JOIN    ods."Attribute"                 AS  A   ON  A."AttributeId" = TA."AttributeId"
        INNER
        JOIN    ods."TaskQueueAttributeLog"     AS  L   ON  L."DataPipeLineTaskQueueId" IN (PrevTaskId, ParentTaskId)
                                                        AND L."AttributeName"   =   A."AttributeName"
        WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId) --  OR Q."ParentTaskId" = DataPipeLineTaskQueueId
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