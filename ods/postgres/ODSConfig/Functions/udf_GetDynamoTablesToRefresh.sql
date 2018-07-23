DROP FUNCTION IF EXISTS ods."udf_GetDynamoTablesToRefresh"(varchar(255), BOOLEAN);
DROP TYPE IF EXISTS ods.DynamoTablesToRefreshList;
CREATE TYPE ods.DynamoTablesToRefreshList as ("DynamoTableSchemaId" INT
                                            , "DataPipeLineTaskId" INT
                                            , "DynamoTableName" VARCHAR(80)
                                            , "S3JsonSchemaPath" VARCHAR(300));
CREATE OR REPLACE FUNCTION ods."udf_GetDynamoTablesToRefresh"(TablesToRefresh VARCHAR(1000) default null
                                                             ,RefreshAll BOOLEAN default null)
RETURNS 
    SETOF ods.DynamoTablesToRefreshList AS $$
DECLARE
    retRecord ods.DynamoTablesToRefreshList%rowtype;

BEGIN
    RAISE NOTICE 'Parmater, RefreshAll: --> %, TablesToRefresh: --> %', RefreshAll, TablesToRefresh;
    RefreshAll := COALESCE(RefreshAll, false);
    TablesToRefresh := COALESCE(TablesToRefresh, '');
    RAISE NOTICE 'Parmater cleaned, RefreshAll: --> %, TablesToRefresh: --> %', RefreshAll, TablesToRefresh;
    
    -- Result
    FOR retRecord in 
        SELECT   D."DynamoTableSchemaId"
                ,D."DataPipeLineTaskId"
                ,D."DynamoTableName" as "DynamoTableName"
                ,D."S3JsonSchemaPath"
        FROM    ods."DynamoTableSchema" AS D
        INNER
        JOIN    ods."DataPipeLineTask"  AS DPL  ON DPL."DataPipeLineTaskId" = D."DataPipeLineTaskId"
        WHERE   1 = 1
        AND     DPL."DeletedFlag" = false
        AND     (
                    (RefreshAll = true)
                OR  (
                        (RefreshAll = false)
                    AND (D."NextRefreshAt" <= CURRENT_TIMESTAMP)
                    AND D."NextRefreshAt" IS NOT NULL
                    AND D."NextRefreshAt" > D."LastRefreshedDate"
                    )
                )
        AND     (
                    (LENGTH(TablesToRefresh) = 0)
                OR  (
                        (LENGTH(TablesToRefresh) > 0)
                    AND (D."SourceEntity" IN (SELECT regexp_split_to_table(TablesToRefresh, E',')))
                    )
                )
    LOOP
        RETURN NEXT retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetDynamoTablesToRefresh"();
    SELECT * FROM ods."udf_GetDynamoTablesToRefresh"('');
    SELECT * FROM ods."udf_GetDynamoTablesToRefresh"('clients,persons', false);
    SELECT * FROM ods."udf_GetDynamoTablesToRefresh"('', false);
    SELECT * FROM ods."udf_GetDynamoTablesToRefresh"('', true);
    SELECT * FROM ods."udf_GetDynamoTablesToRefresh"('clients,persons', true);

    UPDATE ods."DynamoTableSchema" SET "NextRefreshAt" = NULL WHERE "NextRefreshAt" IS NOT NULL 
    UPDATE ods."DynamoTableSchema" SET "NextRefreshAt" = CAST(CURRENT_TIMESTAMP as DATE) + time '00:05' 
    WHERE "NextRefreshAt" IS NULL AND "S3JsonSchemaPath" like '%clients%'

*/