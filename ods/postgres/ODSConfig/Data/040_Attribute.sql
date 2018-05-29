INSERT INTO
    "Attribute"
    (
        "AttributeName"
    )
SELECT "AttributeName"
FROM    (
                    SELECT 'S3.DataFile.FolderPath' as "AttributeName"
            UNION   SELECT 'Prefix.DataFile' as "AttributeName"
            UNION   SELECT 'S3.DataFile' as "AttributeName" -- Output/Input

            UNION   SELECT 'S3.SchemaFile.FolderPath' as "AttributeName"
            UNION   SELECT 'Prefix.SchemaFile' as "AttributeName"
            UNION   SELECT 'S3.SchemaFile' as "AttributeName" -- Output/Input

            UNION   SELECT 'S3.UniformJSON.FolderPath' as "AttributeName"
            UNION   SELECT 'Prefix.UniformJSONFile' as "AttributeName"
            UNION   SELECT 'S3.UniformJSONFile' as "AttributeName" --Output/Input

            UNION   SELECT 'S3.CSVFiles.FolderPath' as "AttributeName"
            UNION   SELECT 'Prefix.CSVFile' as "AttributeName"
            UNION   SELECT 'S3.CSVFile.#' as "AttributeName" --Output/Input
            
            UNION   SELECT 'psql.PreStageTable.Prefix' as "AttributeName"
            UNION   SELECT 'psql.TableName.PreStage' as "AttributeName"
            UNION   SELECT 'psql.TableName.Raw' as "AttributeName"
            UNION   SELECT 'psql.TableName.Clean' as "AttributeName"

            UNION   SELECT 'Dynamo.TableName' as "AttributeName"
            UNION   SELECT 'Dynamo.Table.Index' as "AttributeName"

            UNION   SELECT 'aws.region' as "AttributeName"
        ) as S
WHERE   NOT EXISTS (SELECT 1 FROM "Attribute" AS T WHERE S."AttributeName" = T."AttributeName")
ORDER BY
        "AttributeName";

SELECT * FROM "Attribute";