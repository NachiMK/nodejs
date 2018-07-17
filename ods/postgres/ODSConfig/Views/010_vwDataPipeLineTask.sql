DROP VIEW IF EXISTS ods."vwDataPipeLineTask";
CREATE OR REPLACE VIEW ods."vwDataPipeLineTask"
AS
SELECT   DPL."DataPipeLineTaskId"
        ,DPL."TaskName" as "DataPipeLineTask"
        ,DPL."SourceEntity"
        ,DPL."ParentTaskId"
        ,DPL."RunSequence"
        ,DPL."OnErrorGotoNext"
        ,"TaskTypeDesc" as "TaskType"
        ,DPC."TaskName" as "ConfigTaskName"
        ,DPC."DataPipeLineTaskConfigId"
        ,DPC."ParentId" as "ConfigParentId"
        ,  (
                SELECT  N."DataPipeLineTaskId"
                FROM    ods."DataPipeLineTask" AS N
                WHERE   N."RunSequence" > DPL."RunSequence"
                AND     N."SourceEntity" = DPL."SourceEntity"
                ORDER BY N."RunSequence"
                LIMIT 1
            ) as "NextTaskId"
        ,   (
                SELECT  N."DataPipeLineTaskId"
                FROM    ods."DataPipeLineTask" AS N
                WHERE   N."RunSequence" < DPL."RunSequence"
                AND     N."SourceEntity" = DPL."SourceEntity"
                ORDER BY N."RunSequence" DESC
                LIMIT 1
            ) as "PrevTaskId"
FROM    ods."DataPipeLineTask"  DPL
INNER
JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    ods."TaskType"    AS TS   ON  TS."TaskTypeId" = DPL."TaskTypeId"
WHERE   1 = 1
AND     DPL."DeletedFlag" = false
AND     DPC."DeletedFlag" = false
-- ORDER BY "SourceEntity", DPL."RunSequence"
;