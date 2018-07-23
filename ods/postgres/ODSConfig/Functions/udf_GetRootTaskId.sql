DROP FUNCTION IF EXISTS ods."udf_GetRootTaskId"(INT, INT);
CREATE OR REPLACE FUNCTION ods."udf_GetRootTaskId"(ParentTaskId INT) 
RETURNS 
    INT AS $$
DECLARE
    RootTaskId INT;
BEGIN   
    -- Find the Root ID
    WITH RECURSIVE FindRoot
    AS
    (
        SELECT  CAST(C."AttributeValue" as INT) as PreviousTaskId
        FROM    ods."TaskQueueAttributeLog" as C
        WHERE   C."DataPipeLineTaskQueueId" = ParentTaskId
        AND     C."AttributeName" = 'PreviousTaskId'

        UNION
        
        SELECT  CAST(PT."AttributeValue" as INT) as PreviousTaskId
        FROM    ods."TaskQueueAttributeLog" as PT
        INNER
        JOIN    FindRoot AS R ON R.PreviousTaskId = PT."DataPipeLineTaskQueueId"
        WHERE   "AttributeName" = 'PreviousTaskId'
    )
    SELECT  PreviousTaskId
    INTO    RootTaskId
    FROM    FindRoot
    ORDER BY PreviousTaskId ASC
    LIMIT 1;

    RETURN RootTaskId;
END;
$$ LANGUAGE plpgsql;

/*
    SELECT * FROM ods."udf_GetRootTaskId"(1);
*/