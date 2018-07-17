INSERT INTO ods."DynamoTableSchema"
(
     "DataPipeLineTaskId"
    ,"S3JsonSchemaPath"
    ,"NextRefreshAt"
    ,"LastRefreshedDate"
)
SELECT   "DataPipeLineTaskId"
        ,'s3://dev-ods-data/dynamotableschema/' || DPL."SourceEntity" || '-' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISSMS') || '.json'
        , NULL
        , CURRENT_TIMESTAMP
FROM    ods."DynamoTablesHelper" H
INNER
JOIN    ods."DataPipeLineTask" DPL ON DPL."SourceEntity" = H."CleanTableName"
INNER
JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    ods."DataPipeLineMapping"      DPM  ON  DPM."DataPipeLineMappingId" = DPC."DataPipeLineMappingId"
INNER
JOIN    ods."DataSource" AS S ON S."DataSourceId" = DPM."SourceDataSourceId"
INNER
JOIN    ods."DataSource" AS D ON D."DataSourceId" = DPM."TargetDataSourceId"
WHERE   S."DataSourceName" = 'DynamoDB'
AND     D."DataSourceName" = 'S3/JSON'
AND     "Stage" = 'prod'
AND     NOT EXISTS (SELECT 1 FROM ods."DynamoTableSchema" WHERE "DataPipeLineTaskId" = DPL."DataPipeLineTaskId");
