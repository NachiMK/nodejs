DROP FUNCTION IF EXISTS ods."udf_GetSpecialAttributes"(INT, INT);
CREATE OR REPLACE FUNCTION ods."udf_GetSpecialAttributes"(DataPipeLineTaskQueueId INT, ParentTaskId INT) 
RETURNS 
    SETOF ods."ReturnTypePipeLineAttributes" AS $$
DECLARE
    retRecord ods."ReturnTypePipeLineAttributes"%rowtype;
BEGIN
    IF DataPipeLineTaskQueueId <= 0 THEN
        RAISE EXCEPTION 'DataPipeLineTaskQueueId Cannot be null or less than zero, DataPipeLineTaskQueueId: --> %
        , Parent Task Id: --> %'
            , DataPipeLineTaskQueueId, ParentTaskId
            USING HINT = 'Please check your parameter';
    END IF;

    -- Result
    FOR retRecord in 
        SELECT   Q."DataPipeLineTaskQueueId"
                ,A."AttributeName"
                ,DTS."S3JsonSchemaPath" as "AttributeVale"
        FROM    ods."DataPipeLineTaskQueue" AS Q
        INNER
        JOIN    ods."DataPipeLineTask"      AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
        INNER
        JOIN    ods."TaskConfigAttribute"    AS TA  ON  TA."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
        INNER
        JOIN    ods."Attribute"             AS  A   ON  A."AttributeId" = TA."AttributeId"
        INNER
        JOIN    ods."DynamoTableSchema"     AS  DTS ON  DTS."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
        WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId) 
        AND     A."AttributeName" = 'S3RAWJsonSchemaFile'
    LOOP
        RETURN NEXT retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetSpecialAttributes"(11, 9);
*/
