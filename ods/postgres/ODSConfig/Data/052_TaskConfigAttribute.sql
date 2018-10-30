DROP TABLE IF EXISTS TCAttributeTemp;
CREATE TEMPORARY TABLE TCAttributeTemp
(
     "TaskName"       VARCHAR(50)
    ,"ParentTaskName" VARCHAR(50)
    ,"AttributeName"  VARCHAR(60)
    ,"ParentId"       INT
);

INSERT INTO 
    TCAttributeTemp
    ("TaskName", "ParentTaskName", "AttributeName")
VALUES
     ('DynamoDB to S3', '', 'S3DataFileBucketName')
    ,('DynamoDB to S3', '', 'Prefix.DataFile')
    ,('DynamoDB to S3', '', 'Dynamo.TableName')

    ,('JSON History Data to JSON Schema', 'Process JSON to Postgres', 'S3DataFile')
    ,('JSON History Data to JSON Schema', 'Process JSON to Postgres', 'S3SchemaFileBucketName')
    ,('JSON History Data to JSON Schema', 'Process JSON to Postgres', 'Prefix.SchemaFile')
    ,('JSON History Data to JSON Schema', 'Process JSON to Postgres', 'S3RAWJsonSchemaFile')

    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'S3UniformJSONBucketName')
    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'Prefix.UniformJSONFile')
    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'Prefix.FlatJSONFile')
    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'S3DataFile')
    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'S3SchemaFile')
    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'LogLevel')

    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'S3SchemaFile')
    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'S3FlatJsonFile')
    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'S3CSVFilesBucketName')
    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'Prefix.CSVFile')
    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'LogLevel')

    ,('CSV to Pre-stage', 'Process JSON to Postgres', 'S3SchemaFileBucketName')
    ,('CSV to Pre-stage', 'Process JSON to Postgres', 'Prefix.SchemaFile')
    ,('CSV to Pre-stage', 'Process JSON to Postgres', 'psql.PreStageTable.Prefix')
    ,('CSV to Pre-stage', 'Process JSON to Postgres', 'LogLevel')
    ,('CSV to Pre-stage', 'Process JSON to Postgres', 'S3CSVFile#') -- Dynamic (For copying from Previous Step)

    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'LogLevel')
    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'Prefix.StageSchemaFile')
    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'psql.StageTable.Prefix')
    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'S3SchemaFileBucketName')
    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'DBSchemaStage')
    
    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'S3SchemaFile') -- This is a Json Schema file
    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'S3CSVFile#.PreStageTableName') -- Dynamic (For copying from Previous Step)
    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'S3CSVFile#.JsonObjectName') -- Dynamic (For copying from Previous Step)
    ,('Pre-Stage to Stage', 'Process JSON to Postgres', 'Flat.#.JsonSchemaPath') -- Dynamic (For copying from Previous Step)

    ,('Stage to Clean', 'Process JSON to Postgres', 'S3SchemaFileBucketName') -- Path to save SQL Schema file
    ,('Stage to Clean', 'Process JSON to Postgres', 'Prefix.CleanSchemaFile') -- SQL Script file prefix for S3 
    ,('Stage to Clean', 'Process JSON to Postgres', 'psql.CleanTable.Prefix') -- Clean table prefix
    ,('Stage to Clean', 'Process JSON to Postgres', 'DBSchemaClean') -- Clean table database schema
    ,('Stage to Clean', 'Process JSON to Postgres', 'BusinessKeyColumn') -- Primary key
    
    ,('Stage to Clean', 'Process JSON to Postgres', 'DBSchemaStage') -- Dynamic (will be copied down from previous task)
    ,('Stage to Clean', 'Process JSON to Postgres', 'S3SchemaFile') -- Dynamic (For copying form prior step)This is a Json Schema file
    ,('Stage to Clean', 'Process JSON to Postgres', 'S3CSVFile#.StageTableName') -- Dynamic  (For copying from Previous Step)
    ,('Stage to Clean', 'Process JSON to Postgres', 'S3CSVFile#.JsonObjectName') -- Dynamic (For copying from Previous Step)
    ,('Stage to Clean', 'Process JSON to Postgres', 'S3CSVFile#.JsonSchemaPath') -- Dynamic (For copying from Previous Step)
    ,('Stage to Clean', 'Process JSON to Postgres', 'S3CSVFile#.RowCount') -- Dynamic (For copying from Previous Step)
    ,('Stage to Clean', 'Process JSON to Postgres', 'S3CSVFile#.CleanTableName')
;

UPDATE TCAttributeTemp AS T
SET    "ParentId" = D."DataPipeLineTaskConfigId"
FROM   ods."DataPipeLineTaskConfig" AS D
WHERE   T."ParentId" IS NULL
AND     D."TaskName" = T."ParentTaskName"
AND     D."ParentId" IS NULL;

INSERT INTO
    ods."TaskConfigAttribute"
    (
         "DataPipeLineTaskConfigId"
        ,"AttributeId"
        ,"Required"
        ,"DefaultValue"
    )
SELECT
         "DataPipeLineTaskConfigId"
        ,"AttributeId"
        ,true as "Required"
        ,null "DefaultValue"
FROM
    (
        SELECT  "DataPipeLineTaskConfigId"
                ,A."AttributeId"
        FROM    TCAttributeTemp AS TCT
        INNER
        JOIN    ods."Attribute" AS A ON A."AttributeName" = TCT."AttributeName"
        INNER
        JOIN    ods."DataPipeLineTaskConfig" AS TC ON TC."TaskName" = TCT."TaskName"
                                              AND TC."ParentId" = TCT."ParentId"

        UNION
        
        SELECT  "DataPipeLineTaskConfigId"
                ,A."AttributeId"
        FROM    TCAttributeTemp AS TCT
        INNER
        JOIN    ods."Attribute" AS A ON A."AttributeName" = TCT."AttributeName"
        INNER
        JOIN    ods."DataPipeLineTaskConfig" AS TC ON TC."TaskName" = TCT."TaskName"
                                              AND TC."ParentId" IS NULL

    ) AS STG
WHERE NOT EXISTS (SELECT 1 FROM ods."TaskConfigAttribute" as S 
                 WHERE  S."AttributeId" = STG."AttributeId"
                 AND    S."DataPipeLineTaskConfigId" = STG."DataPipeLineTaskConfigId")
;

SELECT * FROM ods."TaskConfigAttribute";
