SELECT * FROM "AxeneBatch" WHERE "ID" >= 117;

SELECT "AxeneBatchID", "FileName", "Status", "StartDate", "EndDate" 
FROM "AxeneBatchFiles" WHERE "AxeneBatchID" = 117 --IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 113)
AND "Status" != 'started'
ORDER BY "FileName"

SELECT "AxeneBatchID", "FileName", "Status", "StartDate", "EndDate" 
FROM "AxeneBatchFiles" WHERE "AxeneBatchID" = 117 --IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 117)
AND "Status" != 'started'
SELECT * FROM "AxeneBatchFilesHistory" WHERE "AxeneBatchID" = '117'

SELECT * FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 117);
SELECT * FROM "AxenePlanBenefitErrors" WHERE "AxeneBatchFileID" = '117';
SELECT "PlanID", "FileName", Count(*) FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 117)
GROUP BY "PlanID", "FileName"
HAVING COUNT(*) = 2;
-- 108_8e8e412a-3816-4534-b9ed-d6a1e7d85d42_2500_p

SELECT * FROM "AxeneBatchFiles" AS AO WHERE "AxeneBatchID" = 117
AND NOT EXISTS ( SELECT * FROM "AxeneOutputValues" WHERE "AxeneBatchID" = AO."AxeneBatchID" AND "FileName" = AO."FileName");

SELECT 'cp ' || "FileName" || '.json /Users/Nachi/Documents/work/git/axene-scripts/axene-error-converter/inputs/' FROM "AxeneBatchFiles" AS AO WHERE "AxeneBatchID" = 117
AND NOT EXISTS ( SELECT * FROM "AxeneOutputValues" WHERE "AxeneBatchID" = AO."AxeneBatchID" AND "FileName" = AO."FileName");


WITH P
AS
(
SELECT
 "Year"
,"HiosPlanID"
,"PlanMarketingName"
,"State"
,"Carrier"
,"PlanType"
,"Metal"
,"IsHSA"
,"IsActive"
,"IsForSale"
,"IsApproved"
,"UseForModeling"
,"PlanID"
,"GroupID"
,"ActuarialValue"
,"HixmeValuePlus0"
,"HixmeValuePlus500"
,"HixmeValuePlus1000"
,"HixmeValuePlus1500"
,"HixmeValuePlus2000"
,"HixmeValuePlus2500"
FROM "Plans" as P WHERE "IsForSale" = true and "Year" = 2018
)
SELECT json_agg(row_to_json(P)) FROM P;

SELECT * FROM "AxeneOutputValues" WHERE "FileName" IN (
SELECT "FileName" FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 117)
GROUP BY "PlanID", "FileName"
HAVING COUNT(*) > 1)
ORDER BY "FileName";

SELECT * FROM "AxeneOutputValues" WHERE "ID" IN (
SELECT MIN("ID") FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 117)
GROUP BY "PlanID", "FileName"
HAVING COUNT(*) > 1)
ORDER BY "FileName";


SELECT "AxeneBatchID", Count(*) AS Cnt FROM "AxeneBatchFiles" WHERE "AxeneBatchID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 117) GROUP  BY "AxeneBatchID";
SELECT "BatchID" as "AxeneBatchID", Count(*) AS Cnt FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 117) GROUP  BY "BatchID";
SELECT "AxeneBatchFileID", Count(*) AS Cnt FROM "AxenePlanBenefitErrors" WHERE "AxeneBatchFileID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 117) GROUP  BY "AxeneBatchFileID";

SELECT *, "InputFileCount"/6.0 FROM udf_get_AxeneStatus(5, 'day')

SELECT * FROM "PlanServiceAreas" WHERE "HiosPlanID" = '76179IN0110052'
SELECT * FROM "PlanRates" WHERE "HiosPlanID" = '76179IN0110052'
SELECT * FROM "PlanBenefits" WHERE "HiosPlanID" = '76179IN0110052'
SELECT * FROM "Plans" WHERE "HiosPlanID" = '76179IN0110052'
SELECT * FROM "PlanAgeFactor" limit 10;

BEGIN;
DELETE FROM "AxeneOutputValues" WHERE "ID" IN (
SELECT MIN("ID") FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 110)
GROUP BY "PlanID", "FileName"
HAVING COUNT(*) > 1)
COMMIT;
ORDER BY "FileName";

SELECT * FROM "AxeneBatchFiles" WHERE "AxeneBatchID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 117)
AND "FileName" LIKE '111_47db707a-1c30-4588-828a-ff27d35a1879_2000_p%';

SELECT * FROM "AxeneOutputValues" WHERE "BatchID" like '117'
AND "FileName" LIKE '110_47db707a-1c30-4588-828a-ff27d35a1879_2000%';

SELECT MAX("ID") FROM "AxeneBatchFiles"
BEGIN;
with cte
as
(
    SELECT ROW_NUMBER() OVER() as rbr, "AxeneBatchID", "FileName", "Status", "StartDate", "EndDate"  FROM public.stage_axenebatch112
    WHERE "AxeneBatchID" = '117'
)
INSERT INTO "AxeneBatchFiles" ("ID", "AxeneBatchID", "FileName", "Status", "StartDate", "EndDate" )
SELECT 1 + Rbr, "AxeneBatchID", "FileName", "Status", "StartDate", "EndDate"  FROM cte
ROLLBACK;
--COMMIT;

SELECT max("ID") FROM "AxeneOutputValues"
CREATE SEQUENCE "AxeneOutputValues_Seq_ID" MINVALUE 88782;
ALTER TABLE "AxeneOutputValues" ALTER "ID" SET DEFAULT nextval('"AxeneOutputValues_Seq_ID"');
ALTER SEQUENCE "AxeneOutputValues_Seq_ID" OWNED BY "AxeneOutputValues"."ID";

SELECT * FROM "Plans" WHERE "HiosPlanID" = '18029NY1180001' AND "Year" = 2018

INSERT INTO "AxeneBatch" ("ID", "Event")
VALUES (117, '{"body": {}, "query": {"Year": "2018", "State": "WA"}, "stage": "${process.env.STAGE}", "queryStringParameters": {"Year": "2018", "State": "WA"}}')

INSERT INTO "AxeneBatchFiles" ("AxeneBatchID", "FileName", "Status")
VALUES (1, '1_plan_.json', 'Started')

UPDATE "AxeneBatchFiles" SET "Status" = 'File in Axene Output' WHERE "FileName" = '112_44299941-a930-4d43-af30-0f4503489364_0_s'

SELECT * FROM "AxeneBatch";
SELECT * FROM "AxeneBatchFiles" WHERE "Status" = 'started';
SELECT * FROM "AxeneBatchFilesHistory" WHERE "FileName" = '117_0df220fe-d3f7-4456-85c7-80cdf0a289d5_1000_p';
SELECT * FROM "AxeneBatchFilesHistory" WHERE "AxeneBatchID" = '117' AND "Status" = 'success';
SELECT * FROM "AxeneBatchFilesHistory" WHERE "HistoryID" >= 6845
SELECT * FROM "AxeneErrors";

SELECT * FROM "AxeneBatchFilesHistory" WHERE "AxeneBatchID" = '117'
ORDER BY "FileName", "HistoryID" ASC

SELECT * FROM "AxeneBatchFilesHistory" WHERE "RecordCreated" > '2018-06-29 23:08:50'