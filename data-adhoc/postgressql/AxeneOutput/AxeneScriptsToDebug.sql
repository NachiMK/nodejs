SELECT * FROM "AxeneBatch" WHERE "ID" >= 110;
SELECT * FROM "AxeneBatchFiles" WHERE "AxeneBatchID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 110)
ORDER BY "FileName"
;
SELECT * FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 110);
SELECT * FROM "AxenePlanBenefitErrors" WHERE "AxeneBatchFileID" = '110';
SELECT "PlanID", "FileName", Count(*) FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 110)
GROUP BY "PlanID", "FileName"
HAVING COUNT(*) = 2;
-- 108_8e8e412a-3816-4534-b9ed-d6a1e7d85d42_2500_p

SELECT * FROM "AxeneBatchFiles" AS AO WHERE "AxeneBatchID" = 110
AND NOT EXISTS ( SELECT * FROM "AxeneOutputValues" WHERE "AxeneBatchID" = AO."AxeneBatchID" AND "FileName" = AO."FileName");

SELECT * FROM "AxeneOutputValues" WHERE "FileName" IN (
SELECT "FileName" FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 110)
GROUP BY "PlanID", "FileName"
HAVING COUNT(*) > 1)
ORDER BY "FileName";

SELECT * FROM "AxeneOutputValues" WHERE "ID" IN (
SELECT MIN("ID") FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 110)
GROUP BY "PlanID", "FileName"
HAVING COUNT(*) > 1)
ORDER BY "FileName";


SELECT "AxeneBatchID", Count(*) AS Cnt FROM "AxeneBatchFiles" WHERE "AxeneBatchID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 110) GROUP  BY "AxeneBatchID";
SELECT "BatchID" as "AxeneBatchID", Count(*) AS Cnt FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 110) GROUP  BY "BatchID";
SELECT "AxeneBatchFileID", Count(*) AS Cnt FROM "AxenePlanBenefitErrors" WHERE "AxeneBatchFileID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 110) GROUP  BY "AxeneBatchFileID";

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

SELECT * FROM "AxeneBatchFiles" WHERE "AxeneBatchID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 110)
AND "FileName" LIKE '110_47db707a-1c30-4588-828a-ff27d35a1879_2000_p%';

SELECT * FROM "AxeneOutputValues" WHERE "BatchID" like '110'
AND "FileName" LIKE '110_47db707a-1c30-4588-828a-ff27d35a1879_2000%';
