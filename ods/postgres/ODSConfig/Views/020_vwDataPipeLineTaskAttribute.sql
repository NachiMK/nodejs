DROP VIEW IF EXISTS ods."vwDataPipeLineTaskAttribute";
CREATE OR REPLACE VIEW ods."vwDataPipeLineTaskAttribute"
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
        ,A."AttributeName"
        ,TA."AttributeValue"
FROM    ods."DataPipeLineTask"  DPL
INNER
JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    ods."TaskType"    AS TS   ON  TS."TaskTypeId" = DPL."TaskTypeId"
INNER
JOIN    ods."TaskAttribute" AS TA   ON  TA."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
INNER
JOIN    ods."Attribute"     AS A    ON  A."AttributeId" = TA."AttributeId"
AND     DPL."DeletedFlag" = false
;
