CREATE OR REPLACE VIEW ods."vwDataSourceMapping"
AS
SELECT   M."DataPipeLineMappingId"
        ,S."DataSourceId" as "SourceId"
        ,S."DataSourceName" as "Source"
        ,S."ReadOnly" as "SourceReadOnly"
        ,D."DataSourceId" as "TargetId"
        ,D."DataSourceName" as "Target"
        ,D."ReadOnly" as "TargetReadOnly"
FROM    ods."DataPipeLineMapping" AS M
INNER
JOIN    ods."DataSource" AS S ON S."DataSourceId" = M."SourceDataSourceId"
INNER
JOIN    ods."DataSource" AS D ON D."DataSourceId" = M."TargetDataSourceId"
;