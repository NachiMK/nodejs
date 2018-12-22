-- udf_Reset_DataPipeLineTaskQueue
DROP FUNCTION IF EXISTS ods."udf_Reset_DataPipeLineTaskQueue"(int, character varying, character varying);
CREATE OR REPLACE FUNCTION ods."udf_Reset_DataPipeLineTaskQueue"(DataPipeLineTaskQueueId INT
                                                                ,TaskStatus VARCHAR(40)
                                                                ,ResetOption VARCHAR(40))
RETURNS 
    VOID AS $$
DECLARE
    updateTime      TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    taskStatusId    INT;
    Ready_20        INT DEFAULT 20;
    OnHold_10       INT DEFAULT 10;
    IsParent        BOOLEAN DEFAULT false;
    ChildTaskStatusId       INT;
    ParentTaskId            INT DEFAULT -1;
    SibilingTaskStatusId    INT;
BEGIN
    IF ResetOption NOT IN ('ResetTask', 'ResetTaskAndSibilings'
                        ,'DeleteAttributes','DeleteTask'
                        ,'DeleteTaskAndSibilings') THEN
        RETURN;
    END IF;

    IF DataPipeLineTaskQueueId IS NULL THEN
        RETURN;
    END IF;
    
    IF TaskStatus NOT IN ('Ready', 'On Hold') 
        AND ResetOption IN ('ResetTask', 'ResetTaskAndSibilings') THEN
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM ods."DataPipeLineTaskQueue" 
                WHERE "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId
                AND "ParentTaskId" IS NULL) THEN
        IsParent := true;
        ParentTaskId := DataPipeLineTaskQueueId;
    ELSE
        SELECT "ParentTaskId"
        INTO    ParentTaskId 
        FROM    ods."DataPipeLineTaskQueue" 
        WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId;
    END IF;

    SELECT  "TaskStatusId"
    INTO    taskStatusId
    FROM    ods."TaskStatus" 
    WHERE   "TaskStatusDesc" = TaskStatus;

    ChildTaskStatusId := taskStatusId;
    SibilingTaskStatusId := taskStatusId;
    -- If given Task is parent & status is Ready then Child Task should be on hold
    IF taskStatusId = Ready_20 THEN
        ChildTaskStatusId := OnHold_10;
        SibilingTaskStatusId := OnHold_10;
    END IF;

    CREATE TEMPORARY TABLE TmpKeysToUpdate(
         "ResetId"           INT NOT NULL
        ,"DeleteAttributeId" INT NOT NULL
        ,"DeleteId"          INT NOT NULL
    );

    -- Get list of Tasks we want to reset/delete
    INSERT INTO
            TmpKeysToUpdate
    SELECT  CASE WHEN ResetOption IN ('ResetTask', 'ResetTaskAndSibilings') 
                 THEN "DataPipeLineTaskQueueId" 
                 ELSE -1 
            END AS "ResetId"
            ,CASE WHEN ResetOption IN ('DeleteAttributes') 
                 THEN "DataPipeLineTaskQueueId" 
                 ELSE -1 
            END AS "DeleteAttributeId"
            ,CASE WHEN ResetOption IN ('DeleteTask','DeleteTaskAndSibilings') 
                 THEN "DataPipeLineTaskQueueId" 
                 ELSE -1 
            END AS "DeleteId"
    FROM    ods."DataPipeLineTaskQueue" 
    WHERE   "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId;

    INSERT INTO
            TmpKeysToUpdate
    SELECT  CASE WHEN ResetOption IN ('ResetTaskAndSibilings')
                    THEN "DataPipeLineTaskQueueId" 
                 WHEN ResetOption IN ('ResetTask') AND IsParent = TRUE
                    THEN "DataPipeLineTaskQueueId" 
                 ELSE -1 
            END AS "ResetId"
            ,-1 as "DeleteAttributeId"
            ,CASE WHEN ResetOption IN ('DeleteTaskAndSibilings') 
                    THEN "DataPipeLineTaskQueueId" 
                  WHEN ResetOption IN ('DeleteTask') AND IsParent = TRUE
                    THEN "DataPipeLineTaskQueueId" 
                 ELSE -1 
            END AS "DeleteId"
    FROM    ods."DataPipeLineTaskQueue" 
    WHERE   "DataPipeLineTaskQueueId" > DataPipeLineTaskQueueId
    AND     "ParentTaskId" = ParentTaskId;

    -- Rest Task
    IF ResetOption IN ('ResetTask', 'ResetTaskAndSibilings') THEN
        -- Just Update Status
        UPDATE  ods."DataPipeLineTaskQueue" AS DQ
        SET     "TaskStatusId"  = CASE  WHEN DataPipeLineTaskQueueId = DQ."DataPipeLineTaskQueueId" 
                                            AND IsParent = FALSE THEN
                                            taskStatusId
                                        WHEN ParentTaskId = DQ."DataPipeLineTaskQueueId" THEN
                                            taskStatusId
                                        WHEN ParentTaskId != DQ."DataPipeLineTaskQueueId" 
                                            AND ResetOption = 'ResetTask' THEN
                                            ChildTaskStatusId
                                        WHEN ParentTaskId != DQ."DataPipeLineTaskQueueId" 
                                            AND ResetOption = 'ResetTaskAndSibilings' THEN
                                            SibilingTaskStatusId
                                        ELSE
                                            DQ."TaskStatusId"
                                  END
                ,"UpdatedDtTm"  = CURRENT_TIMESTAMP
        FROM    TmpKeysToUpdate AS T 
        WHERE   DQ."DataPipeLineTaskQueueId" = T."ResetId"
        AND     T."ResetId" > 0
        AND     DQ."TaskStatusId" != taskStatusId;

        -- Delete Attributes
        DELETE  FROM ods."TaskQueueAttributeLog"
        WHERE   "DataPipeLineTaskQueueId" in (SELECT "ResetId" FROM TmpKeysToUpdate AS T WHERE T."ResetId" > 0)
        AND     "AttributeName" != 'PreviousTaskId';

    ELSIF ResetOption IN ('DeleteTask', 'DeleteTaskAndSibilings') THEN
        -- Delete Attributes First
        DELETE  FROM ods."TaskQueueAttributeLog"
        WHERE   "DataPipeLineTaskQueueId" in (SELECT "DeleteId" FROM TmpKeysToUpdate AS T WHERE T."DeleteId" > 0);

        -- Delete Sibilings/Child
        DELETE  FROM ods."DataPipeLineTaskQueue"
        WHERE   "DataPipeLineTaskQueueId" in (SELECT "DeleteId" FROM TmpKeysToUpdate AS T WHERE T."DeleteId" > 0)
        AND     "DataPipeLineTaskQueueId" != DataPipeLineTaskQueueId;

        -- Delete Parent/Actual Task
        DELETE  FROM ods."DataPipeLineTaskQueue"
        WHERE   "DataPipeLineTaskQueueId" in (SELECT "DeleteId" FROM TmpKeysToUpdate AS T WHERE T."DeleteId" > 0)
        AND     "DataPipeLineTaskQueueId" = DataPipeLineTaskQueueId;

    ELSIF ResetOption IN ('DeleteAttributes') THEN
        DELETE  FROM ods."TaskQueueAttributeLog"
        WHERE   "DataPipeLineTaskQueueId" in (SELECT "DeleteAttributeId" FROM TmpKeysToUpdate AS T WHERE T."DeleteAttributeId" > 0);
    END IF;

    DROP TABLE IF EXISTS TmpKeysToUpdate;
    RETURN;
END;
$$ LANGUAGE plpgsql;
GRANT ALL ON FUNCTION ods."udf_Reset_DataPipeLineTaskQueue"(int, character varying, character varying) TO odsconfig_user;
/*
    -- Code to test and verify
    -- Delete S3 task
    SELECT  *
    FROM    ods."udf_Reset_DataPipeLineTaskQueue"(22340, '', 'DeleteTask')
    
    -- Test RestTask - Parent Task
    SELECT  *
    FROM    ods."udf_Reset_DataPipeLineTaskQueue"(22341, 'Ready', 'ResetTask')

    -- Test RestTask - Child Task
    SELECT  *
    FROM    ods."udf_Reset_DataPipeLineTaskQueue"(22346, 'On Hold', 'ResetTask')

    -- Test ResetTaskAndSibilings
    SELECT  *
    FROM    ods."udf_Reset_DataPipeLineTaskQueue"(22346, 'On Hold', 'ResetTaskAndSibilings')

    -- Test DeleteTask - Parent Task
    SELECT  *
    FROM    ods."udf_Reset_DataPipeLineTaskQueue"(22341, '', 'DeleteTask')

    -- Test DeleteTask - Child Task
    SELECT  *
    FROM    ods."udf_Reset_DataPipeLineTaskQueue"(22346, '', 'DeleteTask')

    -- Test DeleteTaskAndSibilings
    SELECT  *
    FROM    ods."udf_Reset_DataPipeLineTaskQueue"(22346, '', 'DeleteTaskAndSibilings')
*/