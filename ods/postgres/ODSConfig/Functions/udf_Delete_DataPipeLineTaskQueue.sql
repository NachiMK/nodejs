-- udf_Delete_DataPipeLineTaskQueue
DROP FUNCTION IF EXISTS ods."udf_Delete_DataPipeLineTaskQueue"(jsonb);
CREATE OR REPLACE FUNCTION ods."udf_Delete_DataPipeLineTaskQueue"(TasksToDelete jsonb) 
RETURNS 
    INT AS $$
DECLARE
    rcnt INT;
BEGIN
    IF TasksToDelete IS NULL THEN
        TasksToDelete := '[{"ParentId":-1,"DataPipeLineTaskQueueId":-1,"CreatedDtTm":"2018-01-01"}]'::jsonb;
    END IF;

    CREATE TEMPORARY TABLE TmpDeleteTasks
    (
        "DataPipeLineTaskQueueId" INT NOT NULL
    );

    -- Delete Attributes log first
    DELETE
    FROM    ods."TaskQueueAttributeLog" AS Q
    WHERE   "DataPipeLineTaskQueueId" IN (
                SELECT CAST(CAST(value->'DataPipeLineTaskQueueId' AS VARCHAR(20)) AS INT)
                FROM   jsonb_array_elements(TasksToDelete)
                WHERE  value->'DataPipeLineTaskQueueId' != value->'ParentTaskId'
            );

    WITH CTEDeletes
    AS
    (
    DELETE
    FROM    ods."DataPipeLineTaskQueue" AS Q
    WHERE   "DataPipeLineTaskQueueId" IN (
                SELECT CAST(CAST(value->'DataPipeLineTaskQueueId' AS VARCHAR(20)) AS INT)
                FROM   jsonb_array_elements(TasksToDelete)
                WHERE  CAST(value->'DataPipeLineTaskQueueId' AS VARCHAR(20)) != CAST(value->'ParentTaskId' AS VARCHAR(20))
            )
    RETURNING "DataPipeLineTaskQueueId"
    )
    INSERT INTO
        TmpDeleteTasks
    SELECT  "DataPipeLineTaskQueueId"
    FROM    CTEDeletes;

    -- Get number of rows deleted
    SELECT COUNT(*) + 1
    INTO   rcnt
    FROM   TmpDeleteTasks;

    RAISE NOTICE 'No.Of rows deleted: %', rcnt;

    DROP TABLE IF EXISTS TmpDeleteTasks;

    RETURN rcnt;
    
END;
$$ LANGUAGE plpgsql;
GRANT ALL ON FUNCTION ods."udf_Delete_DataPipeLineTaskQueue"(jsonb) TO odsconfig_user;

/*
    SELECT * 
    FROM ods."udf_Delete_DataPipeLineTaskQueue"('[{"ParentId":946,"DataPipeLineTaskQueueId":948,"CreatedDtTm":"2018-09-13T19:55:21.959271"}]'::jsonb);
*/
