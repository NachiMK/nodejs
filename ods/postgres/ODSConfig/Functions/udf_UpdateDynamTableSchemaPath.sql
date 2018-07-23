DROP FUNCTION IF EXISTS ods."udf_UpdateDynamTableSchemaPath"(int, character varying);
CREATE OR REPLACE FUNCTION ods."udf_UpdateDynamTableSchemaPath"(DynamoTableSchemaId INT
                                                                ,S3JsonSchemaPath VARCHAR(300)
                                                                ,NextRefreshInterval VARCHAR(30) default '3 day') 
RETURNS 
    SETOF ods."DynamoTableSchema" AS $$
DECLARE
    UpdateTime TIMESTAMP;
    retRecord ods."DynamoTableSchema"%rowtype;
    refreshTime TIMESTAMP;
BEGIN
    -- DEBUG
    RAISE NOTICE 'Updating S3 Schema Path for DynamoTableSchemaId: --> % with Path S3JsonSchemaPath --> %'
    , DynamoTableSchemaId, S3JsonSchemaPath;

    -- DEFAULT
    S3JsonSchemaPath := COALESCE(S3JsonSchemaPath, '');
    UpdateTime := CURRENT_TIMESTAMP;

    -- VALIDATION
    IF LENGTH(S3JsonSchemaPath) = 0 THEN
        RAISE EXCEPTION 'S3JsonSchemaPath Cannot be null or empty, S3JsonSchemaPath: --> %'
            , S3JsonSchemaPath
            USING HINT = 'Please check your parameter';
    END IF;

    NextRefreshInterval := COALESCE(NextRefreshInterval, '3 day');
    BEGIN
        SELECT  date_trunc('day', UpdateTime) + interval NextRefreshInterval
        INTO    refreshTime;
    EXCEPTION WHEN OTHERS THEN
        SELECT  date_trunc('day', UpdateTime) + interval '3 day'
        INTO    refreshTime;
    END;

    RAISE NOTICE 'Next REfresh time for DynamoTableSchemaId: --> % Next Refresh At --> %'
    , DynamoTableSchemaId, refreshTime;

    -- UPDATE
    UPDATE  ods."DynamoTableSchema" AS D
    SET     "S3JsonSchemaPath" = S3JsonSchemaPath
            ,"NextRefreshAt" = refreshTime
            ,"LastRefreshedDate" = UpdateTime
            ,"UpdatedDtTm" = UpdateTime
    WHERE   D."DynamoTableSchemaId" = DynamoTableSchemaId
    AND     D."S3JsonSchemaPath" != S3JsonSchemaPath
    AND     LENGTH(S3JsonSchemaPath) != 0;

    -- Result
    FOR retRecord in 
        SELECT  *
        FROM    ods."DynamoTableSchema"
        WHERE   "DynamoTableSchemaId" = DynamoTableSchemaId
    LOOP
        return next retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    -- Code to test and verify
    SELECT * FROM ods."DynamoTableSchema" WHERE "DynamoTableSchemaId" = 19;

    SELECT * FROM ods."udf_UpdateDynamTableSchemaPath"(19, 's3://dev-ods-data/dynamotableschema/clients-20180717_153050191.json');

    SELECT * FROM ods."udf_UpdateDynamTableSchemaPath"(1, '');
    SELECT * FROM ods."udf_UpdateDynamTableSchemaPath"(-1, 'unkn');
*/