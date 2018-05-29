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
     (10, '10.DynamoDB to S3', '', 'DynamoDB', 'S3/JSON', 'Entry')
    ,(20, '20.Process JSON to Postgres', '', 'S3/JSON', 'postgres/clean', 'Entry')
    ,(2010, '2010.JSON History Data to JSON Schema', '20.Process JSON to Postgres', 'S3/JSON', 'S3/JSON', 'Child')
    ,(2020, '2020.JSON History to Flat JSON', '20.Process JSON to Postgres', 'S3/JSON', 'S3/JSON', 'Child')
    ,(2030, '2030.Flat JSON to CSV', '20.Process JSON to Postgres', 'S3/JSON', 'S3/CSV', 'Child')
    ,(2040, '2040.CSV to Pre-stage', '20.Process JSON to Postgres', 'S3/CSV', 'postgres/pre-stage', 'Child')
    ,(2050, '2050.Pre-Stage to RAW', '20.Process JSON to Postgres', 'postgres/pre-stage', 'postgres/raw', 'Child')
    ,(2060, '2060.RAW to Clean', '20.Process JSON to Postgres', 'postgres/raw', 'postgres/clean', 'Child')
    ,(2070, '2070.Verification Process', '20.Process JSON to Postgres', 'postgres/clean', 'postgres/clean', 'Child')
;

INSERT INTO
    public."DataPipeLineTaskConfig"
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
JOIN    public."TaskType" as TT ON TT."TaskTypeDesc" = ST."TaskType"
INNER
JOIN    "DataSource" as S   ON  S."DataSourceName" = ST."Source"
INNER
JOIN    "DataSource" as T   ON  T."DataSourceName" = ST."Target"
INNER
JOIN    "DataPipeLineMapping" STM   ON STM."SourceDataSourceId" = S."DataSourceId" 
                                    AND STM."TargetDataSourceId" = T."DataSourceId"
WHERE   ST."ParentTaskName" = ''
AND     NOT EXISTS (SELECT 1 FROM "DataPipeLineTaskConfig" AS SRC 
                    WHERE SRC."TaskName" = ST."TaskName"
                    AND SRC."TaskTypeId" = TT."TaskTypeId"
                    AND SRC."ParentId" is null
                    AND SRC."DataPipeLineMappingId" = STM."DataPipeLineMappingId")
;

INSERT INTO
    public."DataPipeLineTaskConfig"
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
JOIN    public."TaskType" as TT ON TT."TaskTypeDesc" = ST."TaskType"
INNER
JOIN    "DataSource" as S   ON  S."DataSourceName" = ST."Source"
INNER
JOIN    "DataSource" as T   ON  T."DataSourceName" = ST."Target"
INNER
JOIN    "DataPipeLineMapping" STM   ON STM."SourceDataSourceId" = S."DataSourceId" 
                                    AND STM."TargetDataSourceId" = T."DataSourceId"
INNER
JOIN    "DataPipeLineTaskConfig" as P   ON  P."TaskName" = ST."ParentTaskName"
                                        AND P."ParentId" IS NULL
WHERE   ST."ParentTaskName" != ''
AND     NOT EXISTS (SELECT 1 FROM "DataPipeLineTaskConfig" AS SRC 
                    WHERE SRC."TaskName" = ST."TaskName"
                    AND SRC."TaskTypeId" = TT."TaskTypeId"
                    AND SRC."ParentId"   = P."DataPipeLineTaskConfigId"
                    AND SRC."DataPipeLineMappingId" = STM."DataPipeLineMappingId")
;

SELECT * FROM "DataPipeLineTaskConfig";
