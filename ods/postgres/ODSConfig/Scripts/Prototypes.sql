/*
SELECT udf_InitializeHistoryDownloadQueue();
 -- Find all entries in Task that supports this type of Source - Target Mapping
 -- OF All those Find list of Tasks that are currently running, ignore those
 -- For rest of Tasks make an entry in TaskLog with correct Ranges
 -- State STatus as Ready
 
SELECT udf_InitializeHistoryProcessing();
SELECT udf_GetNextPendingTask();
SELECT udf_UpdateTaskStatus();
*/

select * from "DataPipeLineTaskConfig"

-- Capture History for Dynamo Tables
    -- Create a batch entry for each table

-- Find Next 5 Batches to Process
    -- Kick the Lambda to process each Batch

-- Lambda - Process History

-- Process History

SELECT * FROM "DataPipeLineTaskConfig"
SELECT * FROM "DataPipeLineTask" order by "TaskName", "RunSequence"

SELECT  *
FROM    "DataPipeLineTaskConfig"   DPC --ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    "TaskConfigAttribute"         TA  ON  TA."DataPipeLineTaskConfigId" = DPC."DataPipeLineTaskConfigId"
INNER
JOIN    "Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
WHERE   DPC."TaskName"          = '10.DynamoDB to S3'
;

SELECT  *
FROM    "DataPipeLineTask"  DPL
INNER
JOIN    "DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    "TaskAttribute"         TA  ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
INNER
JOIN    "Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
WHERE   A."AttributeName"       = 'Dynamo.TableName'
AND     DPC."TaskName"          = '10.DynamoDB to S3'
AND     TA."AttributeValue"     =  'prod-clients-history-v2';


SELECT * FROM "DataPipeLineTaskQueue"

SELECT * FROM "udf_createDynamoDBToS3PipeLineTask"('ss', 1);

SELECT * FROM "DataPipeLineTask" WHERE "TaskName" like 'cart%'

INSERT INTO "public"."DataPipeLineTaskQueue" 
(
     "DataPipeLineTaskId"
    ,"ParentTaskId"
    ,"RunSequence"
    ,"TaskStatusId"
    ,"StartDtTm"
    ,"CreatedDtTm"
)
SELECT  DPL."DataPipeLineTaskId"
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
WHERE   1 = 1
--AND     A."AttributeName"       = 'Dynamo.TableName'
AND     DPC."TaskName"          LIKE '%DynamoDB to S3'
AND     TA."AttributeValue"     =  'prod-clients-history-v2'
RETURNING "DataPipeLineTaskQueueId";

SELECT  DPL."DataPipeLineTaskId"
        ,"AttributeName"
        ,"AttributeValue"
        ,DPL."TaskName"
FROM    "DataPipeLineTask"  DPL
INNER
JOIN    "DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    "TaskAttribute"         TA  ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
INNER
JOIN    "Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
WHERE   1 = 1
AND     A."AttributeName"       != 'Dynamo.TableName'
AND     DPL."TaskName"          LIKE 'clients' || '%DynamoDB to S3'


SELECT   DPL."DataPipeLineTaskId"
            ,NULL               AS "ParentTaskId"
            ,DPL."RunSequence"
            ,(SELECT "TaskStatusId" FROM "TaskStatus" WHERE "TaskStatusDesc" = 'Ready') as "TaskStatusId"
            ,CURRENT_TIMESTAMP  AS "StartDtTm"
            ,CURRENT_TIMESTAMP  AS "CreatedDtTm"
            ,"AttributeValue"
    FROM    "DataPipeLineTask"  DPL
    INNER
    JOIN    "DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
    INNER
    JOIN    "TaskAttribute"         TA  ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
    INNER
    JOIN    "Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
    WHERE   A."AttributeName"       = 'Dynamo.TableName'
    AND     DPL."TaskName"          LIKE 'clients' || '%DynamoDB to S3'
    AND     TA."AttributeValue"     LIKE '%' || 'clients';