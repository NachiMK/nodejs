DROP FUNCTION IF EXISTS ods."udf_GetAttributesFromSiblings"(INT);
CREATE OR REPLACE FUNCTION ods."udf_GetAttributesFromSiblings"(DataPipeLineTaskQueueId INT) 
RETURNS 
    SETOF ods."ReturnTypePipeLineAttributes" AS $$
DECLARE
    retRecord ods."ReturnTypePipeLineAttributes"%rowtype;
BEGIN
    IF DataPipeLineTaskQueueId <= 0 THEN
        RAISE EXCEPTION 'DataPipeLineTaskQueueId Cannot be null or less than zero, DataPipeLineTaskQueueId: --> %'
            , DataPipeLineTaskQueueId
            USING HINT = 'Please check your parameter';
    END IF;

    -- Result
    FOR retRecord in 
        WITH CTESiblingAttributes
        AS
        (
        SELECT   Q."DataPipeLineTaskQueueId"
                ,A."AttributeName"
                ,L."AttributeValue"
                ,ROW_NUMBER() OVER (PARTITION BY Q."DataPipeLineTaskQueueId", L."AttributeName" 
                                    ORDER BY SIB."DataPipeLineTaskQueueId") as "SeqNum"
        FROM    ods."DataPipeLineTaskQueue"     AS Q
        INNER
        JOIN    ods."DataPipeLineTask"          AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
        INNER
        JOIN    ods."DataPipeLineTaskConfig"    AS DPC  ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
        INNER
        JOIN    ods."TaskConfigAttribute"       AS  TA  ON  TA."DataPipeLineTaskConfigId" = DPC."DataPipeLineTaskConfigId"
        INNER
        JOIN    ods."Attribute"                 AS  A   ON  A."AttributeId" = TA."AttributeId"
        INNER
        JOIN    ods."TaskQueueAttributeLog"     AS  L   ON  upper(L."AttributeName") = upper(A."AttributeName")
        INNER
        JOIN    ods."DataPipeLineTaskQueue"     AS  SIB ON  SIB."ParentTaskId" = Q."ParentTaskId"
                                                AND SIB."DataPipeLineTaskQueueId" <= DataPipeLineTaskQueueId
                                                AND SIB."DataPipeLineTaskQueueId" = L."DataPipeLineTaskQueueId"
        WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId)
        AND     NOT EXISTS (SELECT  1 
                            FROM    ods."TaskQueueAttributeLog" AS L1 
                            WHERE   Q."DataPipeLineTaskQueueId" = L1."DataPipeLineTaskQueueId" 
                            AND     L."AttributeName" = L1."AttributeName")
        )
        SELECT   "DataPipeLineTaskQueueId"
                ,"AttributeName"
                ,"AttributeValue"
        FROM    CTESiblingAttributes
        WHERE   "SeqNum" = 1
    LOOP
        RETURN NEXT retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetAttributesFromSiblings"(55);
*/
