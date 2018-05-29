DROP FUNCTION IF EXISTS public."udf_createDynamoDBToS3PipeLineTask"(varchar(255), INT);
DROP TYPE IF EXISTS public.DynamoDBtoS3ReturnType;
CREATE TYPE public.DynamoDBtoS3ReturnType as ("DataFilePrefix" VARCHAR(500), "S3DataFileFolderPath" VARCHAR(500), "DataPipeLineTaskQueueId" INT);

CREATE OR REPLACE FUNCTION public."udf_createDynamoDBToS3PipeLineTask"(TableName VARCHAR(255), RowCnt INT) 
RETURNS 
    SETOF DynamoDBtoS3ReturnType AS $$
DECLARE
    retRecord DynamoDBtoS3ReturnType%rowtype;
    dataFilePrefix VARCHAR(200);
    S3DataFileFolderPath VARCHAR(600);
    DataPipeLineTaskQueueId INT;
BEGIN
    IF length(TableName) = 0 THEN
        RAISE EXCEPTION 'TableName Cannot be Empty, TableName: --> %', TableName
            USING HINT = 'Please check your TableName parameter';
    END IF;

    -- Insert a Row
    INSERT INTO "public"."DataPipeLineTaskQueue" 
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
            ,(SELECT "TaskStatusId" FROM "TaskStatus" WHERE "TaskStatusDesc" = 'Ready') as "TaskStatusId"
            ,CURRENT_TIMESTAMP  AS "StartDtTm"
            ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
    FROM    "DataPipeLineTask"  DPL
    INNER
    JOIN    "DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
    INNER
    JOIN    "TaskAttribute"         TA  ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
    INNER
    JOIN    "Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
    WHERE   A."AttributeName"       = 'Dynamo.TableName'
    AND     DPL."TaskName"          LIKE TableName || '%DynamoDB to S3'
    AND     TA."AttributeValue"     LIKE '%' || TableName || '%'
    RETURNING "DataPipeLineTaskQueueId"
    INTO    DataPipeLineTaskQueueId;

    RAISE NOTICE 'Queue Entry to capture data for TableName: --> % was created. ID: %', TableName, DataPipeLineTaskQueueId;
    
    -- Result
    FOR retRecord in 
            SELECT   dataFilePrefix             as "DataFilePrefix"
                    ,S3DataFileFolderPath       as "S3DataFileFolderPath"
                    ,DataPipeLineTaskQueueId    as "DataPipeLineTaskQueueId"
            -- FROM    "DataPipeLineTaskQueue"
            -- WHERE   "DataPipeLineTaskQueueId"   = DataPipeLineTaskQueueId
            LOOP
            return next retRecord;
        END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*

*/