SELECT * FROM ods."DataPipeLineTaskQueue"

SELECT * FROM ods."TaskQueueAttributeLog"

SELECT * FROM ods."udf_GetPipeLineTaskQueueAttribute"(26, false)

SELECT * FROM ods."DynamoTableSchema" WHERE "SourceEntity" = 'clients'

UPDATE ods."DynamoTableSchema" 
SET "S3JsonSchemaPath" = 's3://dev-ods-data/dynamotableschema/clients-20180723_161417408.json' 
WHERE "SourceEntity" = 'clients'
AND   "S3JsonSchemaPath" = 's3://dev-ods-data/dynamotableschema/clients-20180723_165141728.json'

UPDATE ods."TaskQueueAttributeLog" 
SET "AttributeValue" = 's3://dev-ods-data/dynamotableschema/clients-20180723_161417408.json' 
WHERE "AttributeValue" = 's3://dev-ods-data/dynamotableschema/clients-20180723_165141728.json'
AND   "AttributeName"  = 'S3RAWJsonSchemaFile'

UPDATE ods."DataPipeLineTaskQueue"
SET    "TaskStatusId" = 10, "StartDtTm" = null, "EndDtTm" = null, "Error" = null
WHERE  "DataPipeLineTaskQueueId" IN (25, 26)
AND    "TaskStatusId" = 60

UPDATE ods."DataPipeLineTaskQueue"
SET    "TaskStatusId" = 20
WHERE  "DataPipeLineTaskQueueId" IN (25)
AND    "TaskStatusId" = 10

