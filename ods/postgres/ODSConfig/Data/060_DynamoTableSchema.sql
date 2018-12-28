DROP TABLE IF EXISTS DPLTables;
CREATE TEMPORARY TABLE DPLTables
(
     "TableName"             VARCHAR(100)
    ,"CleanTableName"        VARCHAR(100)
);
INSERT INTO 
        DPLTables ("TableName", "CleanTableName")
SELECT  "DynamoTableName" as "TableName"
        ,REPLACE(REPLACE("DynamoTableName", 'prod-', ''), '-history-v2', '') as "CleanTableName"
FROM    ods."DynamoTablesHelper" 
WHERE   "Stage" = 'prod';

INSERT INTO ods."DynamoTableSchema"
(
     "SourceEntity"
    ,"DynamoTableName"
    ,"S3JsonSchemaPath"
    ,"NextRefreshAt"
    ,"LastRefreshedDate"
    ,"DataPipeLineTaskId"
)
SELECT   H."CleanTableName" as "SourceEntity"
        ,H."TableName" as "DynamoTableName"
        ,'s3://dev-ods-data/dynamotableschema/' || DPL."SourceEntity" || '-' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISSMS') || '.json'
        , date_trunc('day', CURRENT_TIMESTAMP + interval '3 day')
        , CURRENT_TIMESTAMP
        ,"DataPipeLineTaskId"
FROM    DPLTables H
INNER
JOIN    ods."DataPipeLineTask" DPL ON DPL."SourceEntity" = H."CleanTableName"
INNER
JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
WHERE   DPC."TaskName" = 'JSON History Data to JSON Schema'
AND     NOT EXISTS (SELECT 1 FROM ods."DynamoTableSchema" WHERE "SourceEntity" = DPL."SourceEntity")
AND     DPL."DeletedFlag" = false;
