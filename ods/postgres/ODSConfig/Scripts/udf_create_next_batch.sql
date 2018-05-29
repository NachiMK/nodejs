
/*

    -- Dynamo Table Name and DataPipeLineMappingId (Parent only)

    -- Look in the Queue
    -- Are there any pending Tasks?
    -- If none then Look at Data pipe line tasks
    -- Create a copy of Tasks in Queue, Set Queue params based on previous successful run

*/


SELECT  *
FROM    "DataPipeLineTaskConfig"   DPC --ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    "TaskConfigAttribute"         TA  ON  TA."DataPipeLineTaskConfigId" = DPC."DataPipeLineTaskConfigId"
INNER
JOIN    "Attribute"             A   ON  A."AttributeId"         = TA."AttributeId"
WHERE   A."AttributeName"       = 'Dynamo.TableName'
AND     DPC."TaskName"          = 'DynamoDB to S3'
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
AND     DPC."TaskName"          = 'DynamoDB to S3'
AND     TA."AttributeValue"     =  'prod-clients-history-v2';

-- Latest run
SELECT  MAX("DataPipeLineTaskQueueId") as LatestId
FROM    "DataPipeLineTaskQueue" AS  Q
WHERE   "DataPipeLineTaskId"    = 19;

-- Latest Run Status
SELECT  "TaskStatusDesc" 
FROM    "DataPipeLineTaskQueue" AS  Q
INNER
JOIN    "TaskStatus"            AS  TS  ON  TS."TaskStatusId" = Q."TaskStatusId"
WHERE   "DataPipeLineTaskId"    = 19
AND     "DataPipeLineTaskQueueId" = 
        (
            SELECT  MAX("DataPipeLineTaskQueueId") as LatestId
            FROM    "DataPipeLineTaskQueue" AS  Q
            WHERE   "DataPipeLineTaskId"    = 19
        );

-- Params of Latest Run

-- Get Next Run details
