DROP VIEW IF EXISTS ods."vwDataPipeLineQueueAttribute";
CREATE OR REPLACE VIEW ods."vwDataPipeLineQueueAttribute"
AS
SELECT   Q."DataPipeLineTaskQueueId"
        ,Q."ParentTaskId"
        ,Q."TaskStatusId"
        ,Q."StartDtTm"
        ,Q."EndDtTm"
        ,Q."RunSequence"
        ,QS."TaskStatusDesc" as "TaskStatus"
        ,Q."DataPipeLineTaskId"
        ,DPL."TaskName" as "DataPipeLineTask"
        ,DPL."SourceEntity"
        ,DPL."ParentTaskId" as "DPLParentTaskId"
        ,DPL."OnErrorGotoNext"
        ,AL."AttributeName"
        ,AL."AttributeValue"
        ,CASE WHEN A."AttributeId" IS NOT NULL THEN true ELSE false END AS "InAttributeTable"
FROM    ods."DataPipeLineTaskQueue" AS Q
INNER
JOIN    ods."DataPipeLineTask"  AS DPL ON  DPL."DataPipeLineTaskId" = Q."DataPipeLineTaskId"
INNER
JOIN    ods."TaskStatus"        AS QS  ON  QS."TaskStatusId" = Q."TaskStatusId"
INNER
JOIN    ods."TaskQueueAttributeLog"  AS AL  ON  AL."DataPipeLineTaskQueueId" = Q."DataPipeLineTaskQueueId"
LEFT
JOIN    ods."Attribute"         AS A   ON  UPPER(A."AttributeName") = UPPER(AL."AttributeName");

/*
    -- Testing code
    SELECT * FROM ods."vwDataPipeLineQueueAttribute" WHERE "SourceEntity" = 'clients'
    ORDER BY "SourceEntity", "DataPipeLineTaskQueueId"
*/