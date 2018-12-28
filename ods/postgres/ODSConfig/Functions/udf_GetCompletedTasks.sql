DROP FUNCTION IF EXISTS ods."udf_GetCompletedTasks"(TEXT, INT, INT);
CREATE OR REPLACE FUNCTION ods."udf_GetCompletedTasks"(Tables TEXT default '', CutOffDays INT default 15, MaxTasks INT default null) 
RETURNS 
    TEXT AS $$
DECLARE
    sql_code TEXT;
    retVal TEXT;
    intervalDays VARCHAR(50);
    TaskConfigName VARCHAR(100);
BEGIN
    TaskConfigName := 'Process JSON to Postgres';

    -- Set to default value if not passed in
    IF CutOffDays IS NULL OR CutOffDays <= 7 OR CutOffDays > 100 THEN
        CutOffDays := 15;
    END IF;

    -- Set to default value if not passed in
    IF MaxTasks IS NULL OR MaxTasks <= 0 OR MaxTasks > 50 THEN
        MaxTasks := 50;
    END IF;

    Tables := COALESCE(TRIM(Tables), '');

    -- First setup Attributes for my task before querying it.
    RAISE NOTICE 'Tables % to get CutOffDay % and MaxTasks %'
    , Tables, CutOffDays, MaxTasks;

    intervalDays := '-' || CAST(CutOffDays AS VARCHAR(10)) || ' days';

    -- Get Parent DatapipeLineTask
    CREATE TEMPORARY TABLE TmpPipeLineTasks AS
    SELECT  DPL."DataPipeLineTaskId" AS TaskId
    FROM    ods."DataPipeLineTask"  AS DPL
    INNER
    JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
    WHERE   (
                (
                    LENGTH(Tables) > 0
                AND DPL."SourceEntity" IN 
                    (SELECT TableName from unnest(string_to_array(Tables, ',')) as TableName)
                )
                OR  LENGTH(Tables) = 0
            )
    AND     DPC."TaskName" = TaskConfigName
    AND     DPL."DeletedFlag"  = false;

    CREATE TEMPORARY TABLE TmpParentTasks AS 
    SELECT  "DataPipeLineTaskQueueId" as ParentId
    FROM    ods."DataPipeLineTaskQueue"
    WHERE   "TaskStatusId" = 50
    AND     "CreatedDtTm" <= CURRENT_TIMESTAMP + intervalDays::interval
    AND     "DataPipeLineTaskId" IN (SELECT TaskId FROM TmpPipeLineTasks)
    LIMIT   MaxTasks;

    SELECT  array_to_json(array_agg(T))
    INTO    retVal
    FROM    (
            SELECT  COALESCE("ParentTaskId", "DataPipeLineTaskQueueId") AS "ParentId", "DataPipeLineTaskQueueId", "CreatedDtTm"
            FROM    ods."DataPipeLineTaskQueue"
            WHERE   (
                        ("ParentTaskId" IS NULL AND "DataPipeLineTaskQueueId" IN (SELECT ParentId FROM TmpParentTasks))
                    OR  ("ParentTaskId" IS NOT NULL AND "ParentTaskId" IN (SELECT ParentId FROM TmpParentTasks))
                    )
    ) AS T;

    DROP TABLE IF EXISTS TmpParentTasks;
    DROP TABLE IF EXISTS TmpPipeLineTasks;

    RETURN retVal;
END;
$$ LANGUAGE plpgsql;
GRANT ALL ON FUNCTION ods."udf_GetCompletedTasks"(TEXT, INT, INT) TO odsconfig_user;
/*
    SELECT * FROM ods."udf_GetCompletedTasks"();
    SELECT * FROM ods."udf_GetCompletedTasks"(null,15,10);
    SELECT * FROM ods."udf_GetCompletedTasks"('clients');
    
    SELECT   jsonb_array_elements(S1::jsonb)->'ParentId' as ParentId
            ,jsonb_array_elements(S1::jsonb)->'DataPipeLineTaskQueueId' as Id 
    FROM    ods."udf_GetCompletedTasks"('enrollments,persons') AS s1
    ORDER BY ParentId, Id desc

    SELECT * FROM ods."udf_GetCompletedTasks"(null,100,100);
    SELECT * FROM ods."udf_GetCompletedTasks"(null,-1,-1);
*/
