CREATE OR REPLACE VIEW ods."vwTaskAttribute" 
AS
    SELECT  A."AttributeId", A."AttributeName", TA."AttributeValue", TA."DataPipeLineTaskId", TA."TaskAttributeId"
    FROM    ods."Attribute" AS A
    INNER
    JOIN    ods."TaskAttribute" AS TA ON TA."AttributeId" = A."AttributeId"

/*
    SELECT  * FROM ods."vwTaskAttribute"
    WHERE   "DataPipeLineTaskId" = 1;
*/
