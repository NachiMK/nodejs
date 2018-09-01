SELECT * FROM "CommandLog";

SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('ods-persons', 1)

SELECt  *
FROM    ods."DataPipeLineTaskQueue"
WHERE   "DataPipeLineTaskQueueId" = 50 or "ParentTaskId" = 50
ORDER BY "RunSequence"

SELECT * FROM ods."TaskStatus"
SELECT * FROM ods."Attribute"

select * from jsonb_each('{"S3DataFile":"s3://ss","S3BucketName":"ods-dev-data","KeyName":"dynamodb/clients/30-ods-data-.csv","RowCount":"0"}')

UPDATE ods."DataPipeLineTaskQueue" SET "TaskStatusId" = 20, "Error" = null, "EndDtTm" = null WHERE "DataPipeLineTaskQueueId" IN (53, 50);
UPDATE ods."DataPipeLineTaskQueue" SET "TaskStatusId" = 10, "Error" = null, "StartDtTm" = null WHERE "DataPipeLineTaskQueueId" IN (54);

SELECT * FROM ods."udf_GetPendingPipeLineTasks"('clients');  

SELECt  *
FROM    ods."DataPipeLineTaskQueue" Q
INNER
JOIN    ods."TaskQueueAttributeLog" TA ON Q."DataPipeLineTaskQueueId" = TA."DataPipeLineTaskQueueId"
WHERE   Q."DataPipeLineTaskQueueId" = 45

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
FROM    ods."DataPipeLineTask" AS DPL
WHERE   "TaskName" LIKE '%' || 'clients' || '%'
AND     "RunSequence" > (SELECT "RunSequence" 
                         FROM   ods."DataPipeLineTask" FT
                         WHERE  FT."DataPipeLineTaskConfigId" = 1
                         AND    FT."TaskName" LIKE 'clients' || '%'
                        )
AND     "DeletedFlag" = false
AND     "ParentTaskId" IS NULL
ORDER BY "RunSequence"
RETURNING "DataPipeLineTaskQueueId"
-- INTO    DataPipeLineTaskQueueId;

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
        ,58  AS "ParentTaskId"
        ,Child."RunSequence"
        ,(SELECT "TaskStatusId" FROM ods."TaskStatus" WHERE "TaskStatusDesc" = 'Ready') as "TaskStatusId"
        ,NULL  AS "StartDtTm"
        ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
FROM    ods."DataPipeLineTaskQueue" AS Q
INNER
JOIN    ods."DataPipeLineTask" AS Child ON Child."ParentTaskId" = Q."DataPipeLineTaskId"
WHERE   "DataPipeLineTaskQueueId" = 2
ORDER  BY
        Child."RunSequence"
        
SELECT  *
FROM    ods."DataPipeLineTaskQueue"
ORDER BY
    "DataPipeLineTaskQueueId"



SELECT * FROM ods."DataPipeLineTask"
WHERE   "TaskName" LIKE '%' || 'ods-persons' || '%'
AND     "RunSequence" > (SELECT "RunSequence" 
                         FROM   ods."DataPipeLineTask" FT
                         WHERE  FT."DataPipeLineTaskConfigId" = 1
                         AND    FT."TaskName" LIKE 'ods-persons' || '%'
                        )
AND     "DeletedFlag" = false
AND     "ParentTaskId" IS NULL
ORDER BY "RunSequence"


SELECT * FROM ods."DataPipeLineTaskConfig"
SELECT * FROM ods."TaskConfigAttribute"

SELECT  DPC.*
FROM    ods."DataPipeLineTask"  DPL
INNER
JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"


SELECT  DPL."DataPipeLineTaskConfigId"
FROM    ods."DataPipeLineTask"  DPL
INNER
JOIN    ods."TaskAttribute"         TA  ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
INNER
JOIN    ods."Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
WHERE   A."AttributeName"       = 'Dynamo.TableName'
AND     DPL."TaskName"          LIKE 'ods-persons' || '%DynamoDB to S3'
AND     TA."AttributeValue"     LIKE '%' || 'ods-persons' || '%'

SELECT * FROM ods."DataPipeLineTaskConfig" WHERE "DataPipeLineMappingId" = 10 
SELECT * FROM ods."DataPipeLineTaskConfig" WHERE "DataPipeLineMappingId" = 10 

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
AND     DPL."TaskName"          LIKE '%DynamoDB to S3'
AND     TA."AttributeValue"     LIKE '%' || 'clients' || '%'


SELECT * FROM ods."TaskAttribute" WHERE "AttributeId" = 3 and "AttributeValue" like '%models%'
SELECT * FROM ods."TaskAttribute" WHERE "AttributeId" = 3 and "AttributeValue" like '%cart%'

SELECT * FROM ods."Attribute";
SELECT * FROM ods."DataPipeLineTaskConfig";
SELECT * FROM ods."DataPipeLineTask" ORDER BY "SourceEntity", "RunSequence" LIMIT 10;

SELECT * FROM ods."DataPipeLineTaskQueue" LIMIT 10;
SELECT * FROM ods."vwDataPipeLineTask" WHERE "DataPipeLineTaskId" = 19
SELECT * FROM ods."vwDataPipeLineTask" WHERE "DataPipeLineTaskId" = 20 OR "ParentTaskId" = 20

SELECT * FROM ods."vwTaskAttribute" WHERE "DataPipeLineTaskId" IN (19);
SELECT * FROM ods."vwTaskAttribute" WHERE "DataPipeLineTaskId" IN (20, 105, 106, 107, 108, 109, 110);

SELECT * FROM ods."TaskQueueAttributeLog" WHERE "DataPipeLineTaskQueueId" = 45;
    
SELECT * FROM ods."TaskConfigAttribute"
-- given a table name I want to find?
-- What are the pipe line tasks/configurations
SELECT * FROM ods."vwDataPipeLineTask" WHERE "SourceEntity" = 'clients';
-- Attributs/configured attribute values
SELECT * FROM ods."vwDataPipeLineTaskAttribute" WHERE "SourceEntity" = 'clients';
-- latest run/attribute log values

SELECT * FROM "CommandLog";

-- If I am a Parent and I have Children, then copy my previous steps parameters that my child are interested to me
-- so that my child can refer to those.

SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('clients', 10);
SELECT * FROM ods."udf_GetPendingPipeLineTasks"('clients');
SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(114, 'Completed', null, '{"EndTime":"06/27/2018 21:01:14.998",
"KeyName":"dynamodb/clients/1-clients-Data-_20180627_210114920.json",
"RowCount":"1",
"StartTime":"06/27/2018 21:01:14.919",
"tableName":"clients",
"S3DataFile":"https://s3-us-west-2.amazonaws.com/dev-ods-data/dynamodb/clients/1-clients-Data-_20180627_210114920.json",
"S3BucketName":"dev-ods-data"}');
SELECT * FROM ods."udf_createDataPipeLine_ProcessHistory"('clients', 114);

SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('persons', 55)


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
    AND     DPL."SourceEntity" LIKE 'clients'
    AND     TA."AttributeValue" LIKE '%persons%'
    
    SELECT * FROM ods."DataPipeLineTask" WHERE "TaskName" like '%persons - DynamoDB to S3'

SELECT  DPL."DataPipeLineTaskId", DPC."TaskName", DPL."RunSequence", DPL."ParentTaskId"
FROM    ods."DataPipeLineTask"  AS DPL
INNER
JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
WHERE   "SourceEntity" = 'clients'
AND     DPC."TaskName" = 'Process JSON to Postgres'

UPDATE ods."DataPipeLineTaskQueue" SET "TaskStatusId" = 20 WHERE "DataPipeLineTaskQueueId" IN (35, 2)

SELECT  *
FROM    ods."DataPipeLineTaskQueue" AS Q
INNER
JOIN    ods."TaskStatus"    AS T    ON T."TaskStatusId" = Q."TaskStatusId"
WHERE   "DataPipeLineTaskId" = 20
AND     "TaskStatusDesc" IN ('Processing');

SELECT  MIN("DataPipeLineTaskQueueId") AS "ParentTaskId"
FROM    ods."DataPipeLineTaskQueue" AS Q
INNER
JOIN    ods."TaskStatus"    AS T    ON T."TaskStatusId" = Q."TaskStatusId"
WHERE   "DataPipeLineTaskId" = 20
AND     "TaskStatusDesc" IN ('Ready')
AND     NOT EXISTS 
        (
            SELECT  *
            FROM    ods."DataPipeLineTaskQueue" AS Q
            INNER
            JOIN    ods."TaskStatus"    AS T    ON T."TaskStatusId" = Q."TaskStatusId"
            WHERE   "DataPipeLineTaskId" = 20
            AND     "TaskStatusDesc" IN ('Processing', 'Error')
        );

SELECT   Q."DataPipeLineTaskQueueId"
        ,T."TaskStatusDesc" AS "Status"
        ,Q."RunSequence"
        ,DPC."TaskName"
        ,*
FROM    ods."DataPipeLineTaskQueue"     AS Q
INNER
JOIN    ods."TaskStatus"                AS T    ON T."TaskStatusId" = Q."TaskStatusId"
INNER
JOIN    ods."DataPipeLineTask"          AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
INNER
JOIN    ods."DataPipeLineTaskConfig"    AS DPC  ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
WHERE   ((Q."DataPipeLineTaskQueueId" = 16) OR (Q."ParentTaskId" = 16))
--AND     T."TaskStatusDesc" IN ('Ready', 'On Hold')
;

SELECT * FROM ods."udf_GetPendingPipeLineTasks"('clients', 41);
SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(9, 'Processing');
SELECT * FROM ods."udf_UpdateDataPipeLineTa˙skQueueStatus"(3, 'Error');
SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(8, 'Completed');

SELECT * FROM ods."TaskStatus" Order by "TaskStatusId"

UPDATE ods."DataPipeLineTaskQueue" SET "TaskStatusId" = 10 WHERE "DataPipeLineTaskQueueId" IN (11);
UPDATE ods."DataPipeLineTaskQueue" SET "TaskStatusId" = 20, "Error" = '{}' WHERE "DataPipeLineTaskQueueId" IN (42, 45);

DELETE
FROM    ods."TaskQueueAttributeLog"
WHERE   "DataPipeLineTaskQueueId" IN (3, 4)
AND     "AttributeName" = 'S3SchemaFile';

SELECT * FROM "CommandLog"

SELECT    TAL."DataPipeLineTaskQueueId"
        ,TAL."AttributeName"
        ,TAL."AttributeValue"
FROM    ods."TaskQueueAttributeLog" AS TAL
WHERE   "DataPipeLineTaskQueueId" >= 3;

UPDATE  ods."TaskQueueAttributeLog" 
SET     "AttributeValue" = 'https://s3-us-west-2.amazonaws.com/dev-ods-data/dynamodb/clients/42-clients-Data-_20180709_163312129.json'
WHERE   "AttributeName" = 'S3DataFile'
AND     "AttributeValue" = 'https://s3-us-west-2.amazonaws.com/dev-ods-data/dynamodb/clients/1-clients-Data-_20180627_134532023.json'
AND     "DataPipeLineTaskQueueId" >= 3;

SELECT  TAL.*
FROM    ods."TaskQueueAttributeLog" AS TAL
WHERE   "DataPipeLineTaskQueueId" IN (42, 43, 44, 45)
ORDER BY "DataPipeLineTaskQueueId"
;

SELECT * FROM ods."udf_GetPipeLineTaskQueueAttribute"(1);
SELECT * FROM ods."udf_GetPipeLineTaskQueueAttribute"(30);
SELECT * FROM ods."udf_GetPipeLineTaskQueueAttribute"(4, true);


SELECT * FROM ods."Attribute" WHERE "AttributeName" = 'S3CSVFilesBucketName'
SELECT * FROM ods."Attribute" WHERE "AttributeName" like 'S3CSV%'
-- UPDATE ods."Attribute" SET "AttributeName" = 'S3CSVFilesBucketName' WHERE "AttributeName" = 'S3CSVFiles.BucketName'

SELECT ods."udf_GetDataPipeLineTaskQueueStatus"(3) as "TaskStatus";

begin;
SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(3, 'Error'
  , '{
  "message": "Saving Schema Failed. Retry Process. Error: The operation is not valid for the object''s storage class", "stack": "Error: Saving Schema Failed. Retry Process. Error: The operation is not valid for the object''s storage class\n    at extractStatusAndAttributes (/Users/Nachi/Documents/work/git/operational-data-store-service/lib/service/ods/json-to-json-schema/index.js:131:26)\n    at DoTaskSaveJsonSchema (/Users/Nachi/Documents/work/git/operational-data-store-service/lib/service/ods/json-to-json-schema/index.js:106:7)\n    at <anonymous>\n    at process._tickCallback (internal/process/next_tick.js:160:7)"
}'
  , '{
  "Prefix.SchemaFile": "dynamodb/clients/2-3-3-clients-Schema-",
  "PreviousTaskId": "2",
  "S3DataFile": "https://s3-us-west-2.amazonaws.com/dev-ods-data/dynamodb/clients/1-clients-Data-_20180627_134532023.json",
  "S3SchemaFileBucketName": "dev-ods-data"
}')
rollback;

SELECT * FROM ods."DynamoTableSchema";

SELECT * FROM ods."udf_createDataPipeLine_ProcessHistory"('clients', 37);

BEGIN;
DELETE FROM ods."TaskQueueAttributeLog" WHERE "DataPipeLineTaskQueueId" IN (
    SELECT "DataPipeLineTaskQueueId" FROM ods."DataPipeLineTaskQueue" WHERE (("ParentTaskId" = 45) OR ("DataPipeLineTaskQueueId" = 45))
);
DELETE FROM ods."DataPipeLineTaskQueue" WHERE "ParentTaskId" = 45;
DELETE FROM ods."DataPipeLineTaskQueue" WHERE "DataPipeLineTaskQueueId" = 45;

TRUNCATE TABLE ods."TaskQueueAttributeLog" CASCADE;
TRUNCATE TABLE ods."DataPipeLineTaskQueueParam" CASCADE;
TRUNCATE TABLE ods."DataPipeLineTaskQueue" CASCADE;
TRUNCATE TABLE ods."DataPipeLineTaskParam" CASCADE;

ROLLBACK;
-- COMMIT;

SELECT * FROM ods."udf_GetDynamoTablesToRefresh"()
SELECT ods."udf_GetRootTaskId"(11) as "RootTaskId";
SELECT * FROM ods."udf_GetMyTaskAttributes"(45, 41, 42);
SELECT * FROM ods."udf_GetMyParentPreviousTaskAttributes"(11, 9, 9);

SELECT * 
       ,CURRENT_TIMESTAMP
       ,CASE WHEN "NextRefreshAt" <= CURRENT_TIMESTAMP THEN 1 ELSE 0 END
FROM ods."DynamoTableSchema" WHERE "DynamoTableSchemaId" = 10;
SELECT date_trunc('day', now()) + interval '3 day'

SELECT * 
       ,CURRENT_TIMESTAMP
       ,CASE WHEN "NextRefreshAt" <= CURRENT_TIMESTAMP THEN 1 ELSE 0 END
FROM    ods."DynamoTableSchema" as D
INNER
JOIN    ods."vwDataPipeLineTask" as V ON V."DataPipeLineTaskId" = D."DataPipeLineTaskId"
WHERE 1 = 1
-- AND "DynamoTableSchemaId" = 10
AND "DataPipeLineTaskId" = ods."udf_GetRootTaskId"(16);

SELECT * FROM ods."vw_DataPipeLineConfig"

SELECT * FROM ods."udf_UpdateDynamTableSchemaPath"(19, '');
SELECT * FROM ods."udf_UpdateDynamTableSchemaPath"(-19, 'unkn');
SELECT ods."udf_UpdateDynamTableSchemaPath"(19, 's3://dev-ods-data/dynamotableschema/clients-20180717_153050393.json');

SELECT   Q."DataPipeLineTaskQueueId"
        ,A."AttributeName"
        ,DTS."S3JsonSchemaPath" as "AttributeVale"
FROM    ods."DataPipeLineTaskQueue" AS Q
INNER
JOIN    ods."DataPipeLineTask"      AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
INNER
JOIN    ods."TaskConfigAttribute"    AS TA  ON  TA."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute"             AS  A   ON  A."AttributeId" = TA."AttributeId"
INNER
JOIN    ods."DynamoTableSchema"     AS  DTS ON  DTS."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
WHERE   (Q."DataPipeLineTaskQueueId" = 11)
AND     A."AttributeName" = 'S3RAWJsonSchemaFile';

SELECT * FROM ods."udf_GetSpecialAttributes"(45, 41);

SELECT * FROM "AxeneBatch" WHERE "ID" >= 42

BEGIN;
SELECT * FROM ods."udf_SetTaskQueueAttributeLog"(45);
COMMIT 

SELECT * FROM ods."DynamoTablesHelper"
SELECT * FROM ods."DataPipeLineTask" WHERE "DataPipeLineMappingId" = 20 AND "DeletedFlag" = false
SELECT * FROM ods."DataPipeLineTaskConfig"