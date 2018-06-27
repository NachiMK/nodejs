DROP FUNCTION IF EXISTS ods."udf_createDynamoDBToS3PipeLineTask"(varchar(255), INT);
DROP TYPE IF EXISTS ods.DynamoDBtoS3ReturnType;
CREATE TYPE ods.DynamoDBtoS3ReturnType as ("DataFilePrefix" VARCHAR(500), "S3DataFileBucketName" VARCHAR(500), "DataPipeLineTaskQueueId" INT);

CREATE OR REPLACE FUNCTION ods."udf_createDynamoDBToS3PipeLineTask"(TableName VARCHAR(255), RowCnt INT) 
RETURNS 
    SETOF ods.DynamoDBtoS3ReturnType AS $$
DECLARE
    retRecord ods.DynamoDBtoS3ReturnType%rowtype;
    dataFilePrefix VARCHAR(200);
    S3DataFileBucketName VARCHAR(600);
    DataPipeLineTaskQueueId INT;
BEGIN
    IF length(TableName) = 0 THEN
        RAISE EXCEPTION 'TableName Cannot be Empty, TableName: --> %', TableName
            USING HINT = 'Please check your TableName parameter';
    END IF;

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
            ,CURRENT_TIMESTAMP  AS "StartDtTm"
            ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
    FROM    ods."DataPipeLineTask"  DPL
    INNER
    JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
    INNER
    JOIN    ods."TaskAttribute"         TA  ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
    INNER
    JOIN    ods."Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
    WHERE   A."AttributeName"       = 'Dynamo.TableName'
    AND     DPL."TaskName"          LIKE TableName || '%DynamoDB to S3'
    AND     TA."AttributeValue"     LIKE '%' || TableName || '%'
    RETURNING "DataPipeLineTaskQueueId"
    INTO    DataPipeLineTaskQueueId;

    RAISE NOTICE 'Queue Entry to capture data for TableName: --> % was created. ID: %', TableName, DataPipeLineTaskQueueId;

    INSERT INTO
        ods."TaskQueueAttributeLog"
        (
             "DataPipeLineTaskQueueId"
            ,"AttributeName"
            ,"AttributeValue"
        )
    SELECT
         DPL."DataPipeLineTaskQueueId"
        ,A."AttributeName" as "AttributeName"
        ,CASE WHEN TA."AttributeValue" LIKE '%{Id}%' 
              THEN REPLACE(TA."AttributeValue", '{Id}', CAST("DataPipeLineTaskQueueId" AS VARCHAR))
              ELSE TA."AttributeValue" 
         END as "AttributeValue"
    FROM    ods."TaskAttribute" AS TA
    INNER
    JOIN    ods."Attribute" AS A ON A."AttributeId" = TA."AttributeId"
    INNER
    JOIN    ods."DataPipeLineTaskQueue" AS DPL ON DPL."DataPipeLineTaskId" = TA."DataPipeLineTaskId"
    WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId;

    -- Result
    FOR retRecord in 
            SELECT   "DataPipeLineTaskQueueId" as "DataPipeLineTaskQueueId"
                    ,"Prefix.DataFile" as "PrefixDataFile"
                    ,"S3DataFileBucketName" as "S3DataFileBucketName"
            FROM    crosstab( 'SELECT    TAL."DataPipeLineTaskQueueId"
                                        ,TAL."AttributeName"
                                        ,TAL."AttributeValue"
                                FROM    ods."TaskQueueAttributeLog" AS TAL
                                WHERE   TAL."DataPipeLineTaskQueueId" = ' || DataPipeLineTaskQueueId) 
                        AS final_result( "DataPipeLineTaskQueueId" INT
                                        ,"Dynamo.TableName"  VARCHAR
                                        ,"Prefix.DataFile" VARCHAR
                                        ,"S3DataFileBucketName" VARCHAR
                                        )
            LOOP
            return next retRecord;
        END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods.udf_createDynamoDBToS3PipeLineTask('clients', 10);
*/