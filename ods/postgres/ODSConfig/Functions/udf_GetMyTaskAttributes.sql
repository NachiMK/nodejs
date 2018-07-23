DROP FUNCTION IF EXISTS ods."udf_GetMyTaskAttributes"(INT, INT, INT);
CREATE OR REPLACE FUNCTION ods."udf_GetMyTaskAttributes"(DataPipeLineTaskQueueId INT, RootTaskId INT, ParentTaskId INT) 
RETURNS 
    SETOF ods."ReturnTypePipeLineAttributes" AS $$
DECLARE
    retRecord ods."ReturnTypePipeLineAttributes"%rowtype;
BEGIN
    IF DataPipeLineTaskQueueId <= 0 THEN
        RAISE EXCEPTION 'DataPipeLineTaskQueueId Cannot be null or less than zero, DataPipeLineTaskQueueId: --> %
        , Root Id: --> %
        , Parent Task Id: --> %'
            , DataPipeLineTaskQueueId, RootTaskId, ParentTaskId
            USING HINT = 'Please check your parameter';
    END IF;

    -- Result
    FOR retRecord in 
        SELECT   Q."DataPipeLineTaskQueueId"
                ,A."AttributeName"
                ,CASE WHEN TA."AttributeValue" LIKE '%.Id}%'
                    THEN 
                        REPLACE(
                                REPLACE(
                                    REPLACE(TA."AttributeValue", '{Root.Id}', CAST(RootTaskId AS VARCHAR(10)))
                                    ,'{Parent.Id}'
                                    ,CAST(ParentTaskId AS VARCHAR(10))
                                    )
                                ,'{My.Id}'
                                ,CAST(DataPipeLineTaskQueueId AS VARCHAR(10))
                                )
                    ELSE TA."AttributeValue"
                END AS "AttributeValue"
        FROM    ods."DataPipeLineTaskQueue" AS Q
        INNER
        JOIN    ods."DataPipeLineTask"      AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
        INNER
        JOIN    ods."TaskAttribute"         AS TA   ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
        INNER
        JOIN    ods."Attribute"             AS  A   ON  A."AttributeId" = TA."AttributeId"
        WHERE   (Q."DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId) -- OR Q."ParentTaskId" = DataPipeLineTaskQueueId
    LOOP
        RETURN NEXT retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetMyTaskAttributes"(2, 1, 1);
*/
