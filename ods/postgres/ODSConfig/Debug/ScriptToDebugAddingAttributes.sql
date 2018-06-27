
    -- Insert a Task for me
/*    INSERT INTO "ods"."DataPipeLineTaskQueue" 
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
    WHERE   DPL."DataPipeLineTaskId" = 20
    AND     DPL."DeletedFlag" = false
    AND     DPL."ParentTaskId" IS NULL
    ORDER BY "RunSequence"
    RETURNING "DataPipeLineTaskQueueId";*/


    -- preserve previous ID just in case for debugging
    -- Copy my Previous Tasks Parameters to me
    -- IF my children are interesetd.
/*    WITH TaskAttributes
    AS
    (
            SELECT  735 as "DataPipeLineTaskQueueId"
                    ,'PreviousTaskId'   as "AttributeName"
                    ,CAST(2 as VARCHAR) as "AttributeValue"

            UNION ALL

            SELECT  DISTINCT Q."DataPipeLineTaskQueueId", L."AttributeName", L."AttributeValue"
            FROM    ods."DataPipeLineTaskQueue"     AS Q
            INNER
            JOIN    ods."DataPipeLineTask"          AS PT   ON  PT."ParentTaskId" = Q."DataPipeLineTaskId"
            INNER
            JOIN    ods."TaskConfigAttribute"       AS  TA  ON  TA."DataPipeLineTaskConfigId" = PT."DataPipeLineTaskConfigId"
            INNER
            JOIN    ods."Attribute"                 AS  A   ON  A."AttributeId" = TA."AttributeId"
            INNER
            JOIN    ods."TaskQueueAttributeLog"     AS  L   ON  L."DataPipeLineTaskQueueId" = 2
                                                            AND L."AttributeName"   =   A."AttributeName"
            WHERE   Q."DataPipeLineTaskQueueId" = 735
            AND     PT."DeletedFlag" = false
    )
    INSERT  INTO ods."TaskQueueAttributeLog"
    (
         "DataPipeLineTaskQueueId"
        ,"AttributeName"
        ,"AttributeValue"
    )
    SELECT  DISTINCT "DataPipeLineTaskQueueId", "AttributeName", "AttributeValue"
    FROM    TaskAttributes;*/

/*    RAISE NOTICE 'Queue Entry to capture data for TableName: --> % was created. ID: %', TableName, DataPipeLineTaskQueueId;*/

    -- Create my Child Tasks
    /*INSERT INTO ods."DataPipeLineTaskQueue" 
    (
        "DataPipeLineTaskId"
        ,"ParentTaskId"
        ,"RunSequence"
        ,"TaskStatusId"
        ,"StartDtTm"
        ,"CreatedDtTm"
    )
    SELECT   Child."DataPipeLineTaskId"
            ,735  AS "ParentTaskId"
            ,Child."RunSequence"
            ,(SELECT "TaskStatusId" FROM ods."TaskStatus" WHERE "TaskStatusDesc" = 'On Hold') as "TaskStatusId"
            ,NULL  AS "StartDtTm"
            ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
    FROM    ods."DataPipeLineTask" AS Child
    WHERE   Child."ParentTaskId" = 20
    AND     Child."ParentTaskId" IS NOT NULL
    AND     Child."DeletedFlag" = false
    ORDER  BY
            Child."RunSequence"
    RETURNING "DataPipeLineTaskQueueId";
    */

    -- Set the Previous Task ID
/*    INSERT  INTO ods."TaskQueueAttributeLog"
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
    WHERE   (Q."DataPipeLineTaskQueueId" = 735 OR Q."ParentTaskId" = 735)
    AND     (PQ."DataPipeLineTaskQueueId" = 735 OR PQ."ParentTaskId" = 735)
    ORDER BY
            Q."DataPipeLineTaskQueueId";*/

    /*SELECT * FROM ods."DataPipeLineTaskQueue" WHERE "ParentTaskId" = 735*/

    -- Create Attributes
    BEGIN;
    SELECT  Q.*, T.*
    FROM    ods."DataPipeLineTaskQueue" AS Q,
    LATERAL ods."udf_SetTaskQueueAttributeLog"(Q."DataPipeLineTaskQueueId", null)  t
    WHERE   Q."ParentTaskId" = 735;
    ROLLBACK;
    
    DROP TABLE IF EXISTS tempPrevTaskID;
    CREATE TEMPORARY TABLE tempPrevTaskID AS 
    SELECT  "DataPipeLineTaskQueueId", CAST("AttributeValue" as INT) AS "PrevTaskId"
    FROM    ods."TaskQueueAttributeLog"
    WHERE   "DataPipeLineTaskQueueId" IN (752,753,754,755,756,757)
    AND     "AttributeName" = 'PreviousTaskId';
        
    CREATE TEMPORARY TABLE tempParentTaskId AS 
    SELECT  "DataPipeLineTaskQueueId", "ParentTaskId"
    FROM    ods."DataPipeLineTaskQueue"
    WHERE   "DataPipeLineTaskQueueId" IN (752,753,754,755,756,757);
    
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
                                    CAST(tp."PrevTaskId" AS VARCHAR(10)) || '-' ||
                                    CAST(tp."DataPipeLineTaskQueueId" AS VARCHAR(10)) || '-' || 
                                    CAST(Q."DataPipeLineTaskQueueId" AS VARCHAR)
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
        INNER
        JOIN    tempPrevTaskID              as tp on tp."DataPipeLineTaskQueueId" = Q."DataPipeLineTaskQueueId"
        --WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId) -- OR Q."ParentTaskId" = DataPipeLineTaskQueueId

        UNION ALL

        -- Copy down Attributes from
        -- my previous task or my Parent Task that I am interested in
        SELECT   Q."DataPipeLineTaskQueueId"
                ,A."AttributeName"
                ,L."AttributeValue"
        FROM    ods."DataPipeLineTaskQueue"     AS Q
        INNER
        JOIN    tempPrevTaskID              as tp on tp."DataPipeLineTaskQueueId" = Q."DataPipeLineTaskQueueId"
        INNER
        JOIN    tempParentTaskId              as tpar on tpar."DataPipeLineTaskQueueId" = Q."DataPipeLineTaskQueueId"
        INNER
        JOIN    ods."DataPipeLineTask"          AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
        INNER
        JOIN    ods."DataPipeLineTaskConfig"    AS DPC  ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
        INNER
        JOIN    ods."TaskConfigAttribute"       AS  TA  ON  TA."DataPipeLineTaskConfigId" = DPC."DataPipeLineTaskConfigId"
        INNER
        JOIN    ods."Attribute"                 AS  A   ON  A."AttributeId" = TA."AttributeId"
        INNER
        JOIN    ods."TaskQueueAttributeLog"     AS  L   ON  L."DataPipeLineTaskQueueId" IN (tp."PrevTaskId", tpar."ParentTaskId")
                                                        AND L."AttributeName"   =   A."AttributeName"
        --WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId) --  OR Q."ParentTaskId" = DataPipeLineTaskQueueId
    )
     INSERT  INTO ods."TaskQueueAttributeLog"
    (
        "DataPipeLineTaskQueueId"
        ,"AttributeName"
        ,"AttributeValue"
    )
    SELECT  DISTINCT 
            "DataPipeLineTaskQueueId"
            ,"AttributeName"
            ,"AttributeValue"
    FROM    MyAttributes;
        
    
/*    -- Mark the Parent as ready for Processing.

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
*//*
    -- SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('clients', 10);
    SELECT * FROM ods."udf_createDataPipeLine_ProcessHistory"('clients', 4);
    SELECT * FROM ods."udf_createDataPipeLine_ProcessHistory"('ods-persons', 4);
*//**/