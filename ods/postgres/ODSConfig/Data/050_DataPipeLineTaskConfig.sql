DROP TABLE IF EXISTS TaskTemp;
CREATE TEMPORARY TABLE TaskTemp
(
     "Seq"            INT NOT NULL
    ,"TaskName"       VARCHAR(50)
    ,"ParentTaskName" VARCHAR(50)
    ,"Source"         VARCHAR(50)
    ,"Target"         VARCHAR(50)
    ,"TaskType"       VARCHAR(20)
);

INSERT INTO 
    TaskTemp
    ("Seq", "TaskName", "ParentTaskName", "Source", "Target", "TaskType")
VALUES
     (10, 'DynamoDB to S3', '', 'DynamoDB', 'S3/JSON', 'Entry')
    ,(20, 'Process JSON to Postgres', '', 'S3/JSON', 'postgres/clean', 'Entry')
    ,(2010, 'JSON History Data to JSON Schema', 'Process JSON to Postgres', 'S3/JSON', 'S3/JSON', 'Child')
    ,(2020, 'JSON History to Flat JSON', 'Process JSON to Postgres', 'S3/JSON', 'S3/JSON', 'Child')
    ,(2030, 'Flat JSON to CSV', 'Process JSON to Postgres', 'S3/JSON', 'S3/CSV', 'Child')
    ,(2040, 'CSV to Pre-stage', 'Process JSON to Postgres', 'S3/CSV', 'postgres/pre-stage', 'Child')
    ,(2050, 'Pre-Stage to Stage', 'Process JSON to Postgres', 'postgres/pre-stage', 'postgres/raw', 'Child')
    ,(2060, 'Stage to Clean', 'Process JSON to Postgres', 'postgres/raw', 'postgres/clean', 'Child')
    ,(2070, 'Verification Process', 'Process JSON to Postgres', 'postgres/clean', 'postgres/clean', 'Child')
;

INSERT INTO
    ods."DataPipeLineTaskConfig"
    (
        "TaskName"
        ,"DataPipeLineMappingId"
        ,"TaskTypeId"
        ,"ParentId"
        ,"RunSequence"
    )
SELECT   
         ST."TaskName"
        ,STM."DataPipeLineMappingId"
        ,TT."TaskTypeId"
        ,CAST(NULL AS INT) AS "ParentId"
        ,ST."Seq"
FROM    TaskTemp AS ST
INNER
JOIN    ods."TaskType" as TT ON TT."TaskTypeDesc" = ST."TaskType"
INNER
JOIN    ods."DataSource" as S   ON  S."DataSourceName" = ST."Source"
INNER
JOIN    ods."DataSource" as T   ON  T."DataSourceName" = ST."Target"
INNER
JOIN    ods."DataPipeLineMapping" STM   ON STM."SourceDataSourceId" = S."DataSourceId" 
                                    AND STM."TargetDataSourceId" = T."DataSourceId"
WHERE   ST."ParentTaskName" = ''
AND     NOT EXISTS (SELECT 1 FROM ods."DataPipeLineTaskConfig" AS SRC 
                    WHERE SRC."TaskName" = ST."TaskName"
                    AND SRC."TaskTypeId" = TT."TaskTypeId"
                    AND SRC."ParentId" is null
                    AND SRC."DataPipeLineMappingId" = STM."DataPipeLineMappingId")
;

INSERT INTO
    ods."DataPipeLineTaskConfig"
    (
        "TaskName"
        ,"DataPipeLineMappingId"
        ,"TaskTypeId"
        ,"ParentId"
        ,"RunSequence"
    )
SELECT   
         ST."TaskName"
        ,STM."DataPipeLineMappingId"
        ,TT."TaskTypeId"
        ,P."DataPipeLineTaskConfigId" AS "ParentId"
        ,ST."Seq"
FROM    TaskTemp AS ST
INNER
JOIN    ods."TaskType" as TT ON TT."TaskTypeDesc" = ST."TaskType"
INNER
JOIN    ods."DataSource" as S   ON  S."DataSourceName" = ST."Source"
INNER
JOIN    ods."DataSource" as T   ON  T."DataSourceName" = ST."Target"
INNER
JOIN    ods."DataPipeLineMapping" STM   ON STM."SourceDataSourceId" = S."DataSourceId" 
                                    AND STM."TargetDataSourceId" = T."DataSourceId"
INNER
JOIN    ods."DataPipeLineTaskConfig" as P   ON  P."TaskName" = ST."ParentTaskName"
                                        AND P."ParentId" IS NULL
WHERE   ST."ParentTaskName" != ''
AND     NOT EXISTS (SELECT 1 FROM ods."DataPipeLineTaskConfig" AS SRC 
                    WHERE SRC."TaskName" = ST."TaskName"
                    AND SRC."TaskTypeId" = TT."TaskTypeId"
                    AND SRC."ParentId"   = P."DataPipeLineTaskConfigId"
                    AND SRC."DataPipeLineMappingId" = STM."DataPipeLineMappingId")
;

-- SELECT * FROM ods."DataPipeLineTaskConfig";
