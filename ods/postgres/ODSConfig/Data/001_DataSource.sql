INSERT INTO
    ods."DataSource"
    (
         "DataSourceId"
        ,"DataSourceName"
    )
SELECT   "DataSourceId"
        ,"DataSourceName"
FROM    (
                    SELECT 10 AS "DataSourceId", 'DynamoDB' as "DataSourceName"
            UNION   SELECT 20 AS "DataSourceId", 'S3/JSON' as "DataSourceName"
            UNION   SELECT 30 AS "DataSourceId", 'S3/CSV' as "DataSourceName"
            UNION   SELECT 40 AS "DataSourceId", 'postgres/pre-stage' as "DataSourceName"
            UNION   SELECT 50 AS "DataSourceId", 'postgres/raw' as "DataSourceName"
            UNION   SELECT 60 AS "DataSourceId", 'postgres/clean' as "DataSourceName"
        ) AS ST
WHERE   NOT EXISTS (SELECT 1 FROM ods."DataSource" AS S WHERE S."DataSourceName" = ST."DataSourceName");

-- SELECT * FROM ods."DataSource";