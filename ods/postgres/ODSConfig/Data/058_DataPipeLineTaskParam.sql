DROP TABLE IF EXISTS DPLTables;
CREATE TEMPORARY TABLE DPLTables
(
      "TableName"           VARCHAR(100)
     ,"CleanTableName"      VARCHAR(100)
);
INSERT INTO DPLTables ("TableName", "CleanTableName")
SELECT "DynamoTableName", "CleanTableName" FROM "DynamoTablesHelper" WHERE "Stage" = 'prod';

INSERT INTO 
    "DataPipeLineTaskParam" 
    (
         "DataPipeLineTaskId"
        ,"RangeTypeId"
        ,"AltRangeTypeId"
        ,"BatchSize"
        ,"InitialRangeValue"
        ,"InitialAltRangeValue"
        ,"Interval"
        ,"IntervalTypeId"
    )
SELECT   DPT."DataPipeLineTaskId"
        ,(SELECT "RangeTypeId" FROM "RangeType" AS R WHERE R."RangeTypeDesc" = 'date') as "RangeTypeId"
        ,(SELECT "RangeTypeId" FROM "RangeType" AS R WHERE R."RangeTypeDesc" = 'timestamp') as "AltRangeTypeId"
        ,-1 as "BatchSize"             
        ,'20160101' as "InitialRangeValue"
        ,'2016-01-01T00:00:00.000Z' as "InitialAltRangeValue"     
        ,10 as "Interval"
        ,(SELECT IT."IntervalTypeId" FROM "IntervalType" AS IT WHERE IT."IntervalTypeDesc" = 'Day')
FROM    DPLTables Tbls, "DataPipeLineTask" DPT
WHERE   DPT."TaskName" = Tbls."CleanTableName" || ' - 10.DynamoDB to S3'
AND     NOT EXISTS (SELECT 1 FROM "DataPipeLineTaskParam" WHERE "DataPipeLineTaskId" = DPT."DataPipeLineTaskId");

SELECT * FROM "DataPipeLineTaskParam";


/*

SELECT  *
FROM    "DataPipeLineTask" AS DPT
WHERE   DPT."TaskName" LIKE 'benefits -%';

SELECT  *
FROM    "DataPipeLineTask" AS DPT
INNER
JOIN    "DataPipeLineTaskParam" AS DPTP ON DPTP."DataPipeLineTaskId" = DPT."DataPipeLineTaskId"
WHERE   DPT."TaskName" LIKE 'benefits -%';

SELECT   DPT."TaskName", A."AttributeName", TA."AttributeValue"
FROM    "DataPipeLineTask" AS DPT
LEFT
JOIN    "TaskAttribute"         AS TA   ON TA."DataPipeLineTaskId" = DPT."DataPipeLineTaskId"
LEFT
JOIN    "Attribute"             AS  A   ON  A."AttributeId" = TA."AttributeId"
WHERE   DPT."TaskName" LIKE 'benefits -%';

*/