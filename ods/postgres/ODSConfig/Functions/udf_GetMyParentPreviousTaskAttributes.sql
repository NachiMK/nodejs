DROP FUNCTION IF EXISTS ods."udf_GetMyParentPreviousTaskAttributes"(INT, INT, INT);
CREATE OR REPLACE FUNCTION ods."udf_GetMyParentPreviousTaskAttributes"(DataPipeLineTaskQueueId INT, PrevTaskId INT, ParentTaskId INT) 
RETURNS 
    SETOF ods."ReturnTypePipeLineAttributes" AS $$
DECLARE
    retRecord ods."ReturnTypePipeLineAttributes"%rowtype;
BEGIN
    IF DataPipeLineTaskQueueId <= 0 THEN
        RAISE EXCEPTION 'DataPipeLineTaskQueueId Cannot be null or less than zero, DataPipeLineTaskQueueId: --> %
        , Prev Task Id: --> %
        , Parent Task Id: --> %'
            , DataPipeLineTaskQueueId, PrevTaskId, ParentTaskId
            USING HINT = 'Please check your parameter';
    END IF;

    -- Result
    FOR retRecord in 
        SELECT   Q."DataPipeLineTaskQueueId"
                ,A."AttributeName"
                ,L."AttributeValue"
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
        JOIN    ods."TaskQueueAttributeLog"     AS  L   ON  L."DataPipeLineTaskQueueId" IN (PrevTaskId, ParentTaskId)
                                                        AND L."AttributeName"   =   A."AttributeName"
        WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId) --  OR Q."ParentTaskId" = DataPipeLineTaskQueueId
    LOOP
        RETURN NEXT retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetMyParentPreviousTaskAttributes"(2, 1, 1);
*/
