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
            UNION   SELECT 'S3UniformJSONFile' as "AttributeName" --Output/Input

            UNION   SELECT 'S3CSVFiles.BucketName' as "AttributeName"
            UNION   SELECT 'Prefix.CSVFile' as "AttributeName"
            UNION   SELECT 'S3CSVFile#' as "AttributeName" --Output/Input
            
            UNION   SELECT 'psql.PreStageTable.Prefix' as "AttributeName"
            UNION   SELECT 'psql.TableName.PreStage' as "AttributeName"
            UNION   SELECT 'psql.TableName.Raw' as "AttributeName"
            UNION   SELECT 'psql.TableName.Clean' as "AttributeName"

            UNION   SELECT 'Dynamo.TableName' as "AttributeName"
            UNION   SELECT 'Dynamo.Table.Index' as "AttributeName"

            UNION   SELECT 'aws.region' as "AttributeName"
        ) as S
WHERE   NOT EXISTS (SELECT 1 FROM ods."Attribute" AS T WHERE S."AttributeName" = T."AttributeName")
ORDER BY
        "AttributeName";

SELECT * FROM ods."Attribute";