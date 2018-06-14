DROP FUNCTION IF EXISTS ods."udf_createDataPipeLine_ProcessHistory"(varchar(255), INT);
DROP TYPE IF EXISTS ods.DynamoDBtoS3ReturnType;
CREATE TYPE ods.DynamoDBtoS3ReturnType as ("DataFilePrefix" VARCHAR(500), "S3DataFileFolderPath" VARCHAR(500), "DataPipeLineTaskQueueId" INT);

CREATE OR REPLACE FUNCTION ods."udf_createDataPipeLine_ProcessHistory"(TableName VARCHAR(255), RowCnt INT) 
RETURNS 
    SETOF ods.DynamoDBtoS3ReturnType AS $$
DECLARE
    retRecord ods.DynamoDBtoS3ReturnType%rowtype;
    dataFilePrefix VARCHAR(200);
    S3DataFileFolderPath VARCHAR(600);
    DataPipeLineTaskQueueId INT;
BEGIN
    IF length(TableName) = 0 THEN
        RAISE EXCEPTION 'TableName Cannot be Empty, TableName: --> %', TableName
            USING HINT = 'Please check your TableName parameter';
    END IF;

    SELECT  DPL."DataPipeLineTaskConfigId"
    FROM    ods."DataPipeLineTask"  DPL
    INNER
    JOIN    ods."TaskAttribute"         TA  ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
    INNER
    JOIN    ods."Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
    WHERE   A."AttributeName"       = 'Dynamo.TableName'
    AND     DPL."TaskName"          LIKE 'ods-persons' || '%DynamoDB to S3'
    AND     TA."AttributeValue"     LIKE '%' || 'ods-persons' || '%';

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
            ,(SELECT "TaskStatusId" FROM ods."TaskStatus" WHERE "TaskStatusDesc" = 'Ready') as "TaskStatusId"
            ,NULL  AS "StartDtTm"
            ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
    FROM    ods."DataPipeLineTask" AS DPL
    WHERE   "TaskName" LIKE '%' || TableName || '%'
    AND     "RunSequence" > (SELECT "RunSequence" 
                            FROM   ods."DataPipeLineTask" FT
                            WHERE  FT."DataPipeLineTaskConfigId" = 1
                            AND    FT."TaskName" LIKE TableName || '%'
                            )
    AND     "DeletedFlag" = false
    AND     "ParentTaskId" IS NULL
    ORDER BY "RunSequence"
    RETURNING "DataPipeLineTaskQueueId"
    INTO    DataPipeLineTaskQueueId;

    INSERT INTO "ods"."DataPipeLineTaskQueue" 
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
            ,(SELECT "TaskStatusId" FROM ods."TaskStatus" WHERE "TaskStatusDesc" = 'Ready') as "TaskStatusId"
            ,NULL  AS "StartDtTm"
            ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
    FROM    ods."DataPipeLineTaskQueue" AS Q
    INNER
    JOIN    ods."DataPipeLineTask" AS Child ON Child."ParentTaskId" = Q."DataPipeLineTaskId"
    WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
    ORDER  BY
            Child."RunSequence";

    RAISE NOTICE 'Queue Entry to capture data for TableName: --> % was created. ID: %', TableName, DataPipeLineTaskQueueId;
    
    -- Result
    FOR retRecord in 
            SELECT  REPLACE("Prefix.DataFile", '{Id}', CAST("DataPipeLineTaskQueueId" AS VARCHAR)) as "PrefixDataFile"
                    ,"S3.DataFile.FolderPath" as "S3DataFileFolderPath"
                    ,"DataPipeLineTaskQueueId" as "DataPipeLineTaskQueueId"
            FROM    crosstab( 'SELECT  "DataPipeLineTaskQueueId"
                                        ,A."AttributeName"
                                        ,TA."AttributeValue"
                                FROM    ods."TaskAttribute" AS TA
                                INNER
                                JOIN    ods."Attribute" AS A ON A."AttributeId" = TA."AttributeId"
                                INNER
                                JOIN    ods."DataPipeLineTaskQueue" AS DPL ON DPL."DataPipeLineTaskId" = TA."DataPipeLineTaskId"
                                WHERE "DataPipeLineTaskQueueId" = ' || DataPipeLineTaskQueueId) 
                        AS final_result( "DataPipeLineTaskQueueId" INT
                                        ,"Dynamo.TableName"  VARCHAR
                                        ,"S3.DataFile.FolderPath" VARCHAR
                                        ,"Prefix.DataFile" VARCHAR
                                        )
            LOOP
            return next retRecord;
        END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods.udf_createDataPipeLine_ProcessHistory('clients', 10);
*/