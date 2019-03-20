INSERT INTO
    ods."Attribute"
    (
        "AttributeName"
    )
SELECT "AttributeName"
FROM    (
                    SELECT 'S3DataFileBucketName' as "AttributeName"
            UNION   SELECT 'Prefix.DataFile' as "AttributeName"
            UNION   SELECT 'S3DataFile' as "AttributeName" -- Output/Input

            UNION   SELECT 'S3SchemaFileBucketName' as "AttributeName"
            UNION   SELECT 'Prefix.SchemaFile' as "AttributeName"
            UNION   SELECT 'S3SchemaFile' as "AttributeName" -- Output/Input
            UNION   SELECT 'S3RAWJsonSchemaFile' as "AttributeName"

            UNION   SELECT 'S3UniformJSONBucketName' as "AttributeName"
            UNION   SELECT 'Prefix.UniformJSONFile' as "AttributeName"
            UNION   SELECT 'Prefix.FlatJSONFile' as "AttributeName"
            UNION   SELECT 'JsonKeysToIgnore' as "AttributeName"
            UNION   SELECT 'S3UniformJSONFile' as "AttributeName" --Output/Input
            UNION   SELECT 'S3FlatJsonFile' as "AttributeName" --Output/Input
            UNION   SELECT 'Flat.#.JsonObjectName' as "AttributeName" --Output/Input
            UNION   SELECT 'Flat.#.JsonSchemaPath' as "AttributeName" --Output/Input

            UNION   SELECT 'S3CSVFilesBucketName' as "AttributeName"
            UNION   SELECT 'Prefix.CSVFile' as "AttributeName"
            UNION   SELECT 'S3CSVFile#' as "AttributeName" --Output/Input
            
            UNION   SELECT 'Prefix.StageSchemaFile' as "AttributeName"
            UNION   SELECT 'psql.PreStageTable.Prefix' as "AttributeName"
            UNION   SELECT 'psql.StageTable.Prefix' as "AttributeName"
            UNION   SELECT 'DBSchemaStage' as "AttributeName"

            UNION   SELECT 'S3CSVFile#.PreStageTableName' as "AttributeName"
            UNION   SELECT 'S3CSVFile#.JsonObjectName' as "AttributeName"
            UNION   SELECT 'S3CSVFile#.StageTableName' as "AttributeName"
            UNION   SELECT 'S3CSVFile#.JsonSchemaPath' as "AttributeName"
            UNION   SELECT 'S3CSVFile#.RowCount' as "AttributeName"
            UNION   SELECT 'Prefix.CleanSchemaFile' as "AttributeName"
            UNION   SELECT 'psql.CleanTable.Prefix' as "AttributeName"
            UNION   SELECT 'DBSchemaClean' as "AttributeName"
            UNION   SELECT 'BusinessKeyColumn' as "AttributeName"

            UNION   SELECT 'Dynamo.TableName' as "AttributeName"
            UNION   SELECT 'Dynamo.Table.Index' as "AttributeName"

            UNION   SELECT 'aws.region' as "AttributeName"
            UNION   SELECT 'LogLevel' as "AttributeName"
        ) as S
WHERE   NOT EXISTS (SELECT 1 FROM ods."Attribute" AS T WHERE S."AttributeName" = T."AttributeName")
ORDER BY
        "AttributeName";

-- SELECT * FROM ods."Attribute";