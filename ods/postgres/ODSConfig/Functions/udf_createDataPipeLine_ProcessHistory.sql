DROP FUNCTION IF EXISTS ods."udf_createDataPipeLine_ProcessHistory"(varchar(255), INT);
CREATE OR REPLACE FUNCTION ods."udf_createDataPipeLine_ProcessHistory"(TableName VARCHAR(255), S3DataPipeLineTaskQueueId INT) 
RETURNS 
    SETOF INTEGER AS $$
DECLARE
    retRecord ods."DataPipeLineTaskQueue"%rowtype;
    dataFilePrefix VARCHAR(200);
    DataPipeLineTaskQueueId INT;
    NextTaskId INT;
BEGIN
    IF length(TableName) = 0 THEN
        RAISE EXCEPTION 'TableName Cannot be Empty, TableName: --> %, S3DataPipeLineTaskQueue: --> %', TableName, S3DataPipeLineTaskQueueId
            USING HINT = 'Please check your TableName parameter';
    END IF;

    SELECT  v."NextTaskId"
    INTO    NextTaskId
    FROM    ods."DataPipeLineTaskQueue" AS DPL
    INNER
    JOIN    ods."vwDataPipeLineTask" as V ON V."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
    WHERE   "DataPipeLineTaskQueueId" = S3DataPipeLineTaskQueueId;

    -- Insert a Row
    INSERT INTO "ods"."DataPipeLineTaskQueue" 
    (
         "DataPipeLineTaskId"
        ,"ParentTaskId"
        ,"RunSequence"
        ,"TaskStatusId"
        ,"StartDtTm"
        ,"CreatedDtTm"
    )
    SELECT   DPL."DataPipeLineTaskId"
            ,NULL               AS "ParentTaskId"
            ,DPL."RunSequence"
            ,(SELECT "TaskStatusId" FROM ods."TaskStatus" WHERE "TaskStatusDesc" = 'On Hold') as "TaskStatusId"
            ,NULL  AS "StartDtTm"
            ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
    FROM    ods."DataPipeLineTask" AS DPL
    WHERE   DPL."DataPipeLineTaskId" = NextTaskId
    AND     DPL."DeletedFlag" = false
    AND     DPL."ParentTaskId" IS NULL
    ORDER BY "RunSequence"
    RETURNING "DataPipeLineTaskQueueId"
    INTO    DataPipeLineTaskQueueId;

    -- preserve previous ID just in case for debugging
    INSERT  INTO ods."TaskQueueAttributeLog"
    (
         "DataPipeLineTaskQueueId"
        ,"AttributeName"
        ,"AttributeValue"
    )
    SELECT  DataPipeLineTaskQueueId, 'PreviousTaskId ', S3DataPipeLineTaskQueueId;

    RAISE NOTICE 'Queue Entry to capture data for TableName: --> % was created. ID: %', TableName, DataPipeLineTaskQueueId;

    INSERT INTO ods."DataPipeLineTaskQueue" 
    (
        "DataPipeLineTaskId"
        ,"ParentTaskId"
        ,"RunSequence"
        ,"TaskStatusId"
        ,"StartDtTm"
        ,"CreatedDtTm"
    )
    SELECT   Child."DataPipeLineTaskId"
            ,DataPipeLineTaskQueueId  AS "ParentTaskId"
            ,Child."RunSequence"
            ,(SELECT "TaskStatusId" FROM ods."TaskStatus" WHERE "TaskStatusDesc" = 'On Hold') as "TaskStatusId"
            ,NULL  AS "StartDtTm"
            ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
    FROM    ods."DataPipeLineTask" AS Child
    WHERE   Child."ParentTaskId" = NextTaskId
    AND     Child."ParentTaskId" IS NOT NULL
    AND     Child."DeletedFlag" = false
    ORDER  BY
            Child."RunSequence";

    INSERT  INTO ods."TaskQueueAttributeLog"
    (
            "DataPipeLineTaskQueueId"
            ,"AttributeName"
            ,"AttributeValue"
    )
    SELECT   Q."DataPipeLineTaskQueueId"
            ,'PreviousTaskId' as "AttributeName"
            ,PQ."DataPipeLineTaskQueueId" as "AttributeValue"
    FROM    ods."DataPipeLineTaskQueue" AS Q
    INNER
    JOIN    ods."DataPipeLineTask"      AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
    INNER
    JOIN    ods."vwDataPipeLineTask"    AS  P   ON  P."DataPipeLineTaskId"   = DPL."DataPipeLineTaskId"
    INNER
    JOIN    ods."DataPipeLineTaskQueue" AS  PQ  ON  PQ."DataPipeLineTaskId"     = P."PrevTaskId"
    WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId OR Q."ParentTaskId" = DataPipeLineTaskQueueId)
    AND     (PQ."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId OR PQ."ParentTaskId" = DataPipeLineTaskQueueId)
    ORDER BY
            Q."DataPipeLineTaskQueueId";

    -- Create Attributes
    INSERT  INTO ods."TaskQueueAttributeLog"
    (
        "DataPipeLineTaskQueueId"
        ,"AttributeName"
        ,"AttributeValue"
    )
    SELECT   Q."DataPipeLineTaskQueueId"
            ,A."AttributeName"
            ,CASE WHEN TA."AttributeValue" LIKE '%{Id}%' 
                THEN REPLACE(TA."AttributeValue"
                            ,'{Id}'
                            ,(
                                CAST(S3DataPipeLineTaskQueueId AS VARCHAR(10)) || '-' ||
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
    WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId OR Q."ParentTaskId" = DataPipeLineTaskQueueId)
    ORDER BY
            Q."DataPipeLineTaskQueueId";
    
    INSERT  INTO ods."TaskQueueAttributeLog"
    (
            "DataPipeLineTaskQueueId"
            ,"AttributeName"
            ,"AttributeValue"
    )
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
    JOIN    ods."TaskQueueAttributeLog"     AS  L   ON  L."DataPipeLineTaskQueueId" = S3DataPipeLineTaskQueueId
                                                    AND L."AttributeName"   =   A."AttributeName"
    WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId OR Q."ParentTaskId" = DataPipeLineTaskQueueId)
    ON  CONFLICT ON CONSTRAINT UNQ_TaskQueueAttributeLog
    DO  UPDATE
        SET "AttributeValue" = EXCLUDED."AttributeValue";

    -- Result
    FOR retRecord in 
        SELECT  *
        FROM    ods."DataPipeLineTaskQueue"
        WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
        OR      "ParentTaskId"            = DataPipeLineTaskQueueId
    LOOP
        RETURN NEXT retRecord."DataPipeLineTaskQueueId";
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_createDataPipeLine_ProcessHistory"('clients', 4);
    SELECT * FROM ods."udf_createDataPipeLine_ProcessHistory"('ods-persons', 4);
*/