
INSERT INTO 
    ods."DataPipeLineMapping"
    (
        "DataPipeLineMappingId"
        ,"SourceDataSourceId"
        ,"TargetDataSourceId"
    )
SELECT
         ST."DataPipeLineMappingId" AS "DataPipeLineMappingId"
        ,S."DataSourceId"   AS "SourceDataSourceId"
        ,T."DataSourceId"   AS "TargetDataSourceId"
FROM    (
                SELECT  10 as "DataPipeLineMappingId", 'DynamoDB'           as "Source", 'S3/JSON'              as  "Target"
        UNION   SELECT  20 as "DataPipeLineMappingId", 'S3/JSON'            as "Source", 'postgres/clean'       as  "Target"
        UNION   SELECT  30 as "DataPipeLineMappingId", 'S3/JSON'            as "Source", 'S3/JSON'              as  "Target"
        UNION   SELECT  40 as "DataPipeLineMappingId", 'S3/JSON'            as "Source", 'S3/CSV'               as  "Target"
        UNION   SELECT  50 as "DataPipeLineMappingId", 'S3/CSV'             as "Source", 'postgres/pre-stage'   as  "Target"
        UNION   SELECT  60 as "DataPipeLineMappingId", 'postgres/pre-stage' as "Source", 'postgres/raw'         as  "Target"
        UNION   SELECT  70 as "DataPipeLineMappingId", 'postgres/raw'       as "Source", 'postgres/clean'       as  "Target"
        ) as ST
INNER
JOIN    ods."DataSource" as S   ON  S."DataSourceName" = ST."Source"
INNER
JOIN    ods."DataSource" as T   ON  T."DataSourceName" = ST."Target"
WHERE   NOT EXISTS (SELECT 1 FROM ods."DataPipeLineMapping" DP 
                    WHERE DP."SourceDataSourceId" = S."DataSourceId" 
                    AND DP."TargetDataSourceId" = T."DataSourceId");

SELECT * FROM ods."DataPipeLineMapping";
