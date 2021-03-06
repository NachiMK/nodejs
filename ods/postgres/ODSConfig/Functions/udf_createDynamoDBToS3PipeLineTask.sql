DROP FUNCTION IF EXISTS ods."udf_createDynamoDBToS3PipeLineTask"(varchar(255), INT);
DROP TYPE IF EXISTS ods.DynamoDBtoS3ReturnType;
CREATE TYPE ods.DynamoDBtoS3ReturnType as ("DataPipeLineTaskQueueId" INT, "DataFilePrefix" VARCHAR(500), "S3DataFileBucketName" VARCHAR(500));

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
    JOIN    ods."DataPipeLineMapping"      DPM  ON  DPM."DataPipeLineMappingId" = DPC."DataPipeLineMappingId"
    INNER
    JOIN    ods."DataSource" AS S ON S."DataSourceId" = DPM."SourceDataSourceId"
    INNER
    JOIN    ods."DataSource" AS D ON D."DataSourceId" = DPM."TargetDataSourceId"
    WHERE   DPL."SourceEntity"      = TableName
    AND     S."DataSourceName" = 'DynamoDB'
    AND     D."DataSourceName" = 'S3/JSON'
    AND     DPL."DeletedFlag"  = false
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
        ,CASE WHEN TA."AttributeValue" LIKE '%.Id}%' 
              THEN REPLACE(TA."AttributeValue", '{My.Id}', CAST("DataPipeLineTaskQueueId" AS VARCHAR))
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
                    ,"Prefix.DataFile" as "DataFilePrefix"
                    ,"S3DataFileBucketName" as "S3DataFileBucketName"
            FROM    crosstab( 'SELECT    TAL."DataPipeLineTaskQueueId"
                                        ,TAL."AttributeName"
                                        ,TAL."AttributeValue"
                                FROM    ods."TaskQueueAttributeLog" AS TAL
                                WHERE   TAL."DataPipeLineTaskQueueId" = ' || DataPipeLineTaskQueueId ||
                                ' 
                                AND     TAL."AttributeName" != ''Dynamo.TableName''
                                ORDER BY TAL."AttributeName"') 
                        AS final_result( "DataPipeLineTaskQueueId" INT
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
    SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('clients', 10);
*/