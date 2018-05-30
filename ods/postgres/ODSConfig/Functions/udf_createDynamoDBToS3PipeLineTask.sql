DROP FUNCTION IF EXISTS ods."udf_createDynamoDBToS3PipeLineTask"(varchar(255), INT);
DROP TYPE IF EXISTS ods.DynamoDBtoS3ReturnType;
CREATE TYPE ods.DynamoDBtoS3ReturnType as ("DataFilePrefix" VARCHAR(500), "S3DataFileFolderPath" VARCHAR(500), "DataPipeLineTaskQueueId" INT);

CREATE OR REPLACE FUNCTION ods."udf_createDynamoDBToS3PipeLineTask"(TableName VARCHAR(255), RowCnt INT) 
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