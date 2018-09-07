-- Testing code
SELECT * FROM ods."vwDataPipeLineQueue" WHERE "SourceEntity" = 'clients'
ORDER BY "SourceEntity", "DataPipeLineTaskQueueId";

-- Testing code
SELECT * FROM ods."vwDataPipeLineQueueAttribute" WHERE "SourceEntity" = 'clients'
ORDER BY "SourceEntity", "DataPipeLineTaskQueueId";

SELECT * FROM ods."vwDataPipeLineTaskAttribute"
WHERE 
"SourceEntity" IN (
 'client-census'
,'persons'
,'enrollments'
,'modeling-price-points'
) AND "ConfigTaskName" = 'DynamoDB to S3'


SELECT * FROM ods."DynamoTableSchema";


SELECT * FROM ods."udf_GetDynamoTablesToRefresh"();