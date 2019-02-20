DROP FUNCTION IF EXISTS ods."udf_Set_DataPipeLineInitialImport"(jsonb);
CREATE OR REPLACE FUNCTION ods."udf_Set_DataPipeLineInitialImport"(FilesToSave jsonb) 
RETURNS TABLE (
     "DataPipeLineInitialImportId" INT
    ,"SourceEntity"                VARCHAR(100)
    ,"S3File"                      VARCHAR(500)
    ,"ImportSequence"              INT
    ,"DataPipeLineTaskQueueId"     INT
    ,"QueuedDtTm"                  TIMESTAMP) AS $$
DECLARE
    sql_code TEXT;
    RowCnt BIGINT;
    DataPipeLineTaskQueueId INT;
    attributes TEXT;
    r record;
BEGIN
    
    IF FilesToSave is null THEN
        RAISE EXCEPTION 'FilesToSave Cannot be NULL'
            USING HINT = 'Please check your FilesToSave parameter';
    END IF;

    CREATE TEMPORARY TABLE Tmp_FilesToSave AS 
    SELECT   REPLACE(CAST(value->'SourceEntity' AS VARCHAR(100)), '"', '') AS "SourceEntity"
            ,CAST(CAST(value->'StartIndex' AS VARCHAR) AS INT) AS "StartIndex"
            ,CAST(CAST(value->'EndIndex' AS VARCHAR) AS INT) AS "EndIndex"
            ,CAST(CAST(value->'RowCountInBatch' AS VARCHAR) AS INT) AS "RowCountInBatch"
            ,CAST(CAST(value->'ImportSequence' AS VARCHAR) AS INT) AS "ImportSequence"
            ,REPLACE(CAST(value->'S3File' AS VARCHAR(500)), '"', '') AS "S3File"
    FROM jsonb_array_elements(FilesToSave)as jsonParams;

    -- How many rows were passed in?
    SELECT COUNT(*)
    INTO   RowCnt
    FROM   Tmp_FilesToSave;
    RAISE NOTICE ' udf_Set_DataPipeLineInitialImport, No Of Rows to Save: %', RowCnt;

    CREATE TEMPORARY TABLE Tmp_InitialImportQueue AS 
    SELECT   T."DataPipeLineInitialImportId"
            ,T."SourceEntity"
            ,T."S3File"
            ,T."ImportSequence"
            ,T."RowCountInBatch"
    FROM    ods."DataPipeLineInitialImport" AS T WITH NO DATA;

    -- SAVE ALL OR NOTHING
    WITH CTEInsert
    AS
    (
        INSERT  INTO ods."DataPipeLineInitialImport" AS A
        (
             "SourceEntity"
            ,"StartIndex"
            ,"EndIndex"
            ,"RowCountInBatch"
            ,"ImportSequence"
            ,"S3File"
            ,"CreatedDtTm"
        )
        SELECT  DISTINCT 
             T."SourceEntity"
            ,T."StartIndex"
            ,T."EndIndex"
            ,T."RowCountInBatch"
            ,T."ImportSequence"
            ,T."S3File"
            ,CURRENT_TIMESTAMP AS "CreatedDtTm"
        FROM  Tmp_FilesToSave AS T
        WHERE EXISTS (SELECT 1 FROM ods."DynamoTablesHelper" AS D WHERE D."CleanTableName" = T."SourceEntity")
        ON  CONFLICT ON CONSTRAINT UNQ_DataPiplelineInitialImport_Seq
        DO  UPDATE
            SET  "S3File" = EXCLUDED."S3File"
                ,"StartIndex" = EXCLUDED."StartIndex"
                ,"EndIndex" = EXCLUDED."EndIndex"
                ,"RowCountInBatch" = EXCLUDED."RowCountInBatch"
                ,"DataPipeLineTaskQueueId" = -1
                ,"QueuingError" = NULL
                ,"QueuedDtTm" = NULL
            WHERE A."S3File" != EXCLUDED."S3File"
        RETURNING A."DataPipeLineInitialImportId", A."SourceEntity", A."S3File", A."ImportSequence", A."RowCountInBatch"
    )
    INSERT INTO Tmp_InitialImportQueue
    SELECT  *
    FROM    CTEInsert;

    -- How many rows were inserted/updated
    SELECT COUNT(*)
    INTO   RowCnt
    FROM   Tmp_InitialImportQueue;
    RAISE NOTICE 'udf_Set_DataPipeLineInitialImport, Rows Inserted/Updated: %', RowCnt;

    IF RowCnt > 0 THEN
        FOR r IN 
            SELECT   T."SourceEntity"
                    ,T."RowCountInBatch"
                    ,T."DataPipeLineInitialImportId"
                    ,REPLACE(T."S3File", 's3://', 'https://s3-us-west-2.amazonaws.com/') as "S3File"
                    ,split_part(T."S3File", '/', 3) as "S3BucketName"
            FROM    Tmp_InitialImportQueue AS T
        LOOP
            RAISE NOTICE 'Creating Pipeline for DataPipeLineInitialImportId ->: %, SourceTable ->: %'
            , r."DataPipeLineInitialImportId", r."SourceEntity";

            -- Create pipe line entries.
            SELECT  T."DataPipeLineTaskQueueId"
            INTO    DataPipeLineTaskQueueId
            FROM    ods."udf_createDynamoDBToS3PipeLineTask"(r."SourceEntity", r."RowCountInBatch") as T;

            -- Get the attributes
            attributes := '{
                "S3DataFile": "' || r."S3File" || '",
                "S3DataFileBucketName": "' || r."S3BucketName" || '",
                "RowCount": ' || CAST(r."RowCountInBatch" AS VARCHAR) || ',
                "S3BucketName": "' || r."S3BucketName" || '",
                "tableName": "' || r."SourceEntity" || '"}';

            -- Update Status with Attribute Values and status
            PERFORM ods."udf_UpdateDataPipeLineTaskQueueStatus"(DataPipeLineTaskQueueId
                                                                ,'Completed'
                                                                ,NULL
                                                                ,attributes::jsonb);

            -- Create the rest of the pipeline tasks
            PERFORM ods."udf_createDataPipeLine_ProcessHistory"(r."SourceEntity", DataPipeLineTaskQueueId);

            -- Update The initial Queue Table with the proper ids
            UPDATE  ods."DataPipeLineInitialImport" AS A
            SET     "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
                    ,"QueuedDtTm" = CURRENT_TIMESTAMP
            WHERE   A."DataPipeLineInitialImportId" = r."DataPipeLineInitialImportId"
            AND     A."DataPipeLineTaskQueueId" != DataPipeLineTaskQueueId;
        END LOOP;
    END IF;

    sql_code = '
    SELECT   A."DataPipeLineInitialImportId"
            ,A."SourceEntity"
            ,A."S3File"
            ,A."ImportSequence"
            ,A."DataPipeLineTaskQueueId"
            ,A."QueuedDtTm"
    FROM    ods."DataPipeLineInitialImport" AS A
    WHERE   EXISTS (SELECT 1 FROM Tmp_InitialImportQueue AS T WHERE T."DataPipeLineInitialImportId" = A."DataPipeLineInitialImportId");
    ';
    RAISE NOTICE 'SQL Code to Return %', sql_code;
    RETURN QUERY EXECUTE sql_code;

    DROP TABLE IF EXISTS Tmp_FilesToSave;
    DROP TABLE IF EXISTS Tmp_InitialImportQueue;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_Set_DataPipeLineInitialImport"('
        [
            {
                "SourceEntity": "benefits",
                "StartIndex": 1,
                "EndIndex": 50,
                "RowCountInBatch": 50,
                "ImportSequence": 0,
                "S3File": "s3://dev-ods-data/dynamodb/benefits/initial/benefits-1-to-50-20181219_200055792.json"
            }
        ]'::jsonb);
*/