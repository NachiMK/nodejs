DROP FUNCTION IF EXISTS ods."udf_GetPendingPipeLineTasks"(varchar(255), INT);
DROP TYPE IF EXISTS ods.PendingPipeLineTasks;
CREATE TYPE ods.PendingPipeLineTasks as ("DataPipeLineTaskQueueId" INT, "Status" VARCHAR(40), "RunSequence" INT, "TaskConfigName" VARCHAR(200));
CREATE OR REPLACE FUNCTION ods."udf_GetPendingPipeLineTasks"(TableName VARCHAR(255), ParentTaskId INT default null) 
RETURNS 
    SETOF ods.PendingPipeLineTasks AS $$
DECLARE
    retRecord ods.PendingPipeLineTasks%rowtype;
    DataPipeLineTaskId INT;
    ParentQueueID   INT;
    TaskConfigName VARCHAR(100);

BEGIN
    IF length(TableName) = 0 THEN
        RAISE EXCEPTION 'TableName Cannot be Empty, TableName: --> %, ParentTaskId: --> %', TableName, ParentTaskId
            USING HINT = 'Please check your TableName parameter';
    END IF;

    TaskConfigName := 'Process JSON to Postgres';

    -- Get DatapipeLineTask
    SELECT  DPL."DataPipeLineTaskId"
    INTO    DataPipeLineTaskId
    FROM    ods."DataPipeLineTask"  AS DPL
    INNER
    JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
    WHERE   "SourceEntity" = TableName
    AND     DPC."TaskName" = TaskConfigName;

    RAISE NOTICE 'GetPendingTasks DataPipeLineTaskId: --> %', DataPipeLineTaskId;

    SELECT  MIN("DataPipeLineTaskQueueId")
    INTO    ParentQueueID
    FROM    ods."DataPipeLineTaskQueue" AS Q
    INNER
    JOIN    ods."TaskStatus"    AS T    ON T."TaskStatusId" = Q."TaskStatusId"
    WHERE   "DataPipeLineTaskId" = DataPipeLineTaskId
    AND     "TaskStatusDesc" IN ('Ready')
    AND     NOT EXISTS 
            (
                SELECT  *
                FROM    ods."DataPipeLineTaskQueue" AS Q
                INNER
                JOIN    ods."TaskStatus"    AS T    ON T."TaskStatusId" = Q."TaskStatusId"
                WHERE   "DataPipeLineTaskId" = DataPipeLineTaskId
                AND     "TaskStatusDesc" IN ('Processing', 'Error')
            );

    RAISE NOTICE 'GetPendingTasks ParentQueueID: --> %', ParentQueueID;

    IF ParentQueueID IS NULL THEN
        ParentQueueID := -1;
    END IF;    

    -- Result
    FOR retRecord in 
        SELECT   Q."DataPipeLineTaskQueueId"
                ,T."TaskStatusDesc" AS "Status"
                ,Q."RunSequence"
                ,DPC."TaskName" as "TaskConfigName"
        FROM    ods."DataPipeLineTaskQueue"     AS Q
        INNER
        JOIN    ods."TaskStatus"                AS T    ON T."TaskStatusId" = Q."TaskStatusId"
        INNER
        JOIN    ods."DataPipeLineTask"          AS DPL  ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
        INNER
        JOIN    ods."DataPipeLineTaskConfig"    AS DPC  ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
        WHERE   ((Q."DataPipeLineTaskQueueId" = ParentQueueID) OR (Q."ParentTaskId" = ParentQueueID))
        AND     T."TaskStatusDesc" IN ('Ready', 'On Hold')
        ORDER BY
                Q."RunSequence"
    LOOP
        RETURN NEXT retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetPendingPipeLineTasks"('clients', null);
*/