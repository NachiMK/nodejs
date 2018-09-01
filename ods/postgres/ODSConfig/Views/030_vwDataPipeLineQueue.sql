DROP VIEW IF EXISTS ods."vwDataPipeLineQueue";
CREATE OR REPLACE VIEW ods."vwDataPipeLineQueue"
AS
SELECT   Q."DataPipeLineTaskQueueId"
        ,Q."ParentTaskId"
        ,Q."TaskStatusId"
        ,Q."StartDtTm"
        ,Q."EndDtTm"
        ,Q."RunSequence"
        ,QS."TaskStatusDesc" as "TaskStatus"
        ,DPL."DataPipeLineTaskId"
        ,DPL."TaskName" as "DataPipeLineTask"
        ,DPL."SourceEntity"
        ,DPL."ParentTaskId" as "DPLParentTaskId"
        ,DPL."OnErrorGotoNext"
        ,"TaskTypeDesc" as "TaskType"
        ,DPC."TaskName" as "ConfigTaskName"
        ,DPC."DataPipeLineTaskConfigId"
        ,jsonb_pretty(Q."Error") as "Error"
FROM    ods."DataPipeLineTaskQueue" Q
INNER
JOIN    ods."DataPipeLineTask"  DPL ON DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
INNER
JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    ods."TaskType"    AS TS   ON  TS."TaskTypeId" = DPL."TaskTypeId"
INNER
JOIN    ods."TaskStatus" AS QS   ON  QS."TaskStatusId" = Q."TaskStatusId";

/*
    -- Testing code
    SELECT * FROM ods."vwDataPipeLineQueue" WHERE "SourceEntity" = 'clients'
    ORDER BY "SourceEntity", "DataPipeLineTaskQueueId"
*/