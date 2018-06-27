DROP VIEW IF EXISTS ods."vwDataPipeLineTaskConfigAttribute";
CREATE OR REPLACE VIEW ods."vwDataPipeLineTaskConfigAttribute"
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
        ,TCAA."AttributeName"
        ,TCA."DefaultValue"
        ,TCA."Required"
FROM    ods."DataPipeLineTask"  DPL
INNER
JOIN    ods."TaskType"    AS TS   ON  TS."TaskTypeId" = DPL."TaskTypeId"
INNER
JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
INNER
JOIN    ods."TaskConfigAttribute"      TCA  ON  TCA."DataPipeLineTaskConfigId" = DPC."DataPipeLineTaskConfigId"
INNER
JOIN    ods."Attribute"                 TCAA    ON  TCAA."AttributeId" = TCA."AttributeId"
WHERE   1= 1
AND     DPL."DeletedFlag" = false;
