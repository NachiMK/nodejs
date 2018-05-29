DROP TABLE IF EXISTS DPLTables;
CREATE TEMPORARY TABLE DPLTables
(
     "TableName"             VARCHAR(100)
    ,"CleanTableName"        VARCHAR(100)
);
INSERT INTO DPLTables ("TableName", "CleanTableName")
SELECT "DynamoTableName", REPLACE(REPLACE("DynamoTableName", 'prod-', ''), '-history-v2', '') FROM "DynamoTablesHelper" WHERE "Stage" = 'prod';

INSERT INTO
    "TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,Tbls."TableName" AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    "DataPipeLineTask" DPT   ON DPT."TaskName" LIKE  Tbls."CleanTableName" || ' - %'
INNER
JOIN    "TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    "Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" = 'Dynamo.TableName'
AND     NOT EXISTS (SELECT 1 FROM "TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId");

INSERT INTO
    "TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'s3://dev-ods-data/dynamodb/{Id}/' || Tbls."CleanTableName" || '/'  AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    "DataPipeLineTask" DPT   ON DPT."TaskName" LIKE Tbls."CleanTableName" || ' - %'
INNER
JOIN    "TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    "Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" LIKE 'S3.%.FolderPath'
AND     NOT EXISTS (SELECT 1 FROM "TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId");

INSERT INTO
    "TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'{Id}-' || Tbls."CleanTableName" || '-' || REPLACE(REPLACE(A."AttributeName", 'Prefix.', ''), 'File', '') || '-' AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    "DataPipeLineTask" DPT   ON DPT."TaskName" LIKE Tbls."CleanTableName" || ' - %'
INNER
JOIN    "TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    "Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" LIKE 'Prefix.%File'
AND     NOT EXISTS (SELECT 1 FROM "TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId");

INSERT INTO
    "TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'{Id}_stage_' || REPLACE(lower(Tbls."CleanTableName"), '-', '_') || '_' AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    "DataPipeLineTask" DPT   ON DPT."TaskName" LIKE Tbls."CleanTableName" || ' - %'
INNER
JOIN    "TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    "Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" LIKE 'psql.PreStageTable.Prefix'
AND     NOT EXISTS (SELECT 1 FROM "TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId");

SELECT * FROM "TaskAttribute";
