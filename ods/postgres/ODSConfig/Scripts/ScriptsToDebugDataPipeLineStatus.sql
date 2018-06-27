SELECT * FROM "CommandLog";

SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('ods-persons', 1)

SELECt  *
FROM    ods."DataPipeLineTaskQueue"
WHERE   "DataPipeLineTaskQueueId" = 20

SELECT * FROM ods."Attribute"

select * from jsonb_each('{"S3DataFile":"s3://ss","S3BucketName":"ods-dev-data","KeyName":"dynamodb/clients/30-ods-data-.csv","RowCount":"0"}')
  

SELECt  *
FROM    ods."DataPipeLineTaskQueue" Q
INNER
JOIN    ods."TaskQueueAttributeLog" TA ON TA."DataPipeLineTaskQueueId" = TA."DataPipeLineTaskQueueId"
WHERE   Q."DataPipeLineTaskQueueId" = 20

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
WHERE   "DataPipeLineTaskQueueId" = 2 OR "ParentTaskId" = 2



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

SELECT * FROM ods."vwTaskAttribute" WHERE "DataPipeLineTaskId" IN (820);

SELECT * FROM ods."vwTaskAttribute" WHERE "DataPipeLineTaskId" IN (1019);

SELECT * FROM ods."TaskQueueAttributeLog" WHERE "DataPipeLineTaskQueueId" = 12;
    
SELECT * FROM ods."TaskConfigAttribute"
-- given a table name I want to find?
-- What are the pipe line tasks/configurations
SELECT * FROM ods."vwDataPipeLineTask" WHERE "SourceEntity" = 'clients';
-- Attributs/configured attribute values
SELECT * FROM ods."vwDataPipeLineTaskAttribute" WHERE "SourceEntity" = 'clients';
-- latest run/attribute log values

SELECT * FROM "CommandLog"