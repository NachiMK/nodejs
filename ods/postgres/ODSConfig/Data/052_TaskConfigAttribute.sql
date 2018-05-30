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
     ('DynamoDB to S3', '', 'S3.DataFile.FolderPath')
    ,('DynamoDB to S3', '', 'Prefix.DataFile')
    ,('DynamoDB to S3', '', 'Dynamo.TableName')

    ,('JSON History Data to JSON Schema', 'Process JSON to Postgres', 'S3.DataFile')
    ,('JSON History Data to JSON Schema', 'Process JSON to Postgres', 'S3.SchemaFile.FolderPath')
    ,('JSON History Data to JSON Schema', 'Process JSON to Postgres', 'Prefix.SchemaFile')

    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'S3.UniformJSON.FolderPath')
    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'Prefix.UniformJSONFile')
    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'S3.DataFile')
    ,('JSON History to Flat JSON', 'Process JSON to Postgres', 'S3.SchemaFile')

    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'S3.SchemaFile')
    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'S3.UniformJSONFile')
    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'S3.CSVFiles.FolderPath')
    ,('Flat JSON to CSV', 'Process JSON to Postgres', 'Prefix.CSVFile')

    ,('CSV to Pre-stage', 'Process JSON to Postgres', 'S3.CSVFile.#')
    ,('CSV to Pre-stage', 'Process JSON to Postgres', 'psql.PreStageTable.Prefix')

    ,('Pre-Stage to RAW', 'Process JSON to Postgres', 'psql.TableName.PreStage')
    ,('Pre-Stage to RAW', 'Process JSON to Postgres', 'psql.TableName.Raw')

    ,('RAW to Clean', 'Process JSON to Postgres', 'psql.TableName.Raw')
    ,('RAW to Clean', 'Process JSON to Postgres', 'psql.TableName.Clean')
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