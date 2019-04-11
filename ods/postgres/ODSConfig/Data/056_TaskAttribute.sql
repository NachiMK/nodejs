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

INSERT INTO
    ods."TaskAttribute"
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
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" = 'Dynamo.TableName'
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'dev-ods-data'
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" LIKE 'S3%BucketName'
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'dynamodb/' || Tbls."CleanTableName" || 
        CASE WHEN DPT."ParentTaskId" IS NULL THEN '/{My.Id}/{My.Id}-' ELSE '/{Root.Id}/{Parent.Id}-{My.Id}-' END
        || Tbls."CleanTableName" || '-' || REPLACE(REPLACE(A."AttributeName", 'Prefix.', ''), 'File', '') || '-' AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" LIKE 'Prefix.%File'
AND     A."AttributeName" != 'Prefix.StageSchemaFile'
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

;WITH CTEIgnoreKeys
AS
(
    SELECT 'ods-testtable-1' as "SourceEntity", 'BenefitsBackup' as "PathsToIgnore"
    UNION SELECT 'benefits' as "SourceEntity", 'input' as "PathsToIgnore"
    UNION SELECT 'enrollments' as "SourceEntity", 'CartBackup,BundleGroupsOld,HixmeRecommendedBundleGroupsOld' as "PathsToIgnore"
    UNION SELECT 'prospect-census-models' as "SourceEntity", 'PlanBestMatchesWithPlanType.MatchingPlans' as "PathsToIgnore"
    UNION SELECT 'modeling-configuration' as "SourceEntity", 'Validation.AvailablePlanSummary.Carriers' as "PathsToIgnore"
)
INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,C."PathsToIgnore"
FROM    DPLTables Tbls
INNER
JOIN    CTEIgnoreKeys AS C ON C."SourceEntity" = Tbls."CleanTableName"
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" LIKE 'JsonKeysToIgnore'
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'dynamodb/' || Tbls."CleanTableName" || 
        CASE WHEN DPT."ParentTaskId" IS NULL THEN '/{My.Id}/{My.Id}-' ELSE '/{Root.Id}/{Parent.Id}-{My.Id}-' END
        || 'StgDB-'  AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" = 'Prefix.StageSchemaFile'
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'dynamodb/' || Tbls."CleanTableName" || 
        CASE WHEN DPT."ParentTaskId" IS NULL THEN '/{My.Id}/{My.Id}-' ELSE '/{Root.Id}/{Parent.Id}-{My.Id}-' END
        || 'Clean-'  AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" = 'Prefix.CleanSchemaFile'
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,REPLACE(lower(Tbls."CleanTableName"), '-', '_') || '{My.Id}_' AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" LIKE 'psql.PreStageTable.Prefix'
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,REPLACE(lower(Tbls."CleanTableName"), '-', '_') || '_' AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" IN ('psql.StageTable.Prefix', 'psql.CleanTable.Prefix')
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'warn' AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" LIKE 'LogLevel'
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,CASE WHEN A."AttributeName" = 'DBSchemaStage' THEN 'stg' ELSE 'public' END AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" IN ('DBSchemaClean', 'DBSchemaStage')
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

INSERT INTO
    ods."TaskAttribute"
    (
         "DataPipeLineTaskId"
        ,"AttributeId"
        ,"AttributeValue"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,TCA."AttributeId"
        ,'Rowkey' AS "AttributeValue"
FROM    DPLTables Tbls
INNER
JOIN    ods."DataPipeLineTask" DPT   ON DPT."SourceEntity" =  Tbls."CleanTableName"
INNER
JOIN    ods."TaskConfigAttribute" AS TCA ON TCA."DataPipeLineTaskConfigId" = DPT."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute" AS A ON A."AttributeId" = TCA."AttributeId"
WHERE   A."AttributeName" IN ('BusinessKeyColumn')
AND     NOT EXISTS (SELECT 1 FROM ods."TaskAttribute" WHERE "AttributeId" = TCA."AttributeId" AND "DataPipeLineTaskId" = DPT."DataPipeLineTaskId")
AND     DPT."DeletedFlag" = false;

-- SELECT * FROM ods."TaskAttribute";
