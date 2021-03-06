DROP TABLE IF EXISTS DPLTables;
CREATE TEMPORARY TABLE DPLTables
(
      "TableName"             VARCHAR(100)
     ,"CleanTableName"        VARCHAR(100)
);
INSERT INTO DPLTables ("TableName", "CleanTableName")
SELECT "DynamoTableName", "CleanTableName" FROM ods."DynamoTablesHelper" WHERE "Stage" = 'prod';

DROP TABLE IF EXISTS DLPTasksTemp;
CREATE TEMPORARY TABLE DLPTasksTemp AS
SELECT  
         "TaskName"
        ,"DataPipeLineTaskConfigId"
        ,"DataPipeLineMappingId"
        ,"TaskTypeId"
        ,"ParentId"
        ,"RunSequence"
FROM    ods."DataPipeLineTaskConfig"
WHERE   (("TaskName" LIKE '%DynamoDB to S3%') OR ("TaskName" LIKE  '%Process JSON to Postgres%'))
AND     "ParentId" IS NULL;

INSERT INTO
        ods."DataPipeLineTask"
        ("TaskName", "SourceEntity", "DataPipeLineTaskConfigId", "DataPipeLineMappingId", "TaskTypeId", "ParentTaskId", "RunSequence")
SELECT   Tbls."CleanTableName" || ' - ' || "TaskName"  as "TaskName"
        ,Tbls."CleanTableName" as "SourceEntity"
        ,TT."DataPipeLineTaskConfigId"
        ,TT."DataPipeLineMappingId"
        ,TT."TaskTypeId"
        ,NULL AS "ParentTaskId"
        ,TT."RunSequence"
FROM    DLPTasksTemp TT, DPLTables Tbls
WHERE NOT EXISTS (
                  SELECT 1 FROM ods."DataPipeLineTask" TGT
                  WHERE TGT."DataPipeLineMappingId" = TT."DataPipeLineMappingId"
                  AND   TGT."DataPipeLineTaskConfigId" = TT."DataPipeLineTaskConfigId"
                  AND   TGT."ParentTaskId" IS NULL
                  AND   TGT."SourceEntity" = Tbls."CleanTableName"
                 )
AND   TT."ParentId" IS NULL
ORDER BY
        Tbls."TableName", TT."RunSequence"
;

INSERT INTO
        ods."DataPipeLineTask"
        ("TaskName", "SourceEntity", "DataPipeLineTaskConfigId", "DataPipeLineMappingId", "TaskTypeId", "ParentTaskId", "RunSequence")
SELECT   REPLACE(DPL."TaskName", P."TaskName", C."TaskName") as "TaskName"
        ,DPL."SourceEntity"
        ,C."DataPipeLineTaskConfigId"
        ,C."DataPipeLineMappingId"
        ,C."TaskTypeId"
        ,DPL."DataPipeLineTaskId" AS "ParentTaskId"
        ,C."RunSequence"
FROM    ods."DataPipeLineTaskConfig" AS C
INNER
JOIN    ods."DataPipeLineTaskConfig" AS P ON P."DataPipeLineTaskConfigId" = C."ParentId"
INNER
JOIN    ods."DataPipeLineTask" as DPL ON DPL."DataPipeLineTaskConfigId" = P."DataPipeLineTaskConfigId"
WHERE   ((P."TaskName" LIKE '%DynamoDB to S3%') OR (P."TaskName" LIKE  '%Process JSON to Postgres%'))
AND     C."ParentId" IS NOT NULL
AND     NOT EXISTS (
                  SELECT 1 FROM ods."DataPipeLineTask" TGT
                  WHERE TGT."SourceEntity" = DPL."SourceEntity"
                  AND   TGT."DataPipeLineMappingId" = C."DataPipeLineMappingId"
                  AND   TGT."DataPipeLineTaskConfigId" = C."DataPipeLineTaskConfigId"
                  AND   TGT."ParentTaskId" = DPL."DataPipeLineTaskId"
                 )
ORDER   BY
    DPL."TaskName", C."RunSequence"
;


-- SELECT  *
-- FROM   ods."DataPipeLineTask" as DPL
-- ORDER   BY
--    LEFT("TaskName", 20), "TaskTypeId", "RunSequence"
-- ;
