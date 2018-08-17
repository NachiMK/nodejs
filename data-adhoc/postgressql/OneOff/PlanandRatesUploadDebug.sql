-- DROP TABLE plans_dev.public.stage_plans_clean

SELECT *
FROM   udf_create_plans_stage_tables('testdeploy')

SELECT  *
FROM    udf_clean_stage_plans();

SELECT  *
FROM    "udf_Get_PlansAndRates"('true', '2018', '', '') as Report

SELECT * FROM stage_plans_clean;
SELECT DISTINCT "StageTableName" FROM stage_plans_clean
ORDER BY 1 DESC;
SELECT * FROM vw_stage_plans_raw WHERE "Projected Rate Increase Type" NOT IN ('N', 'S', 'C', 'P');

UPDATE vw_stage_plans_raw SET "Projected Rate Increase Type" = 'p' WHERE "Hios Plan ID" = '83761GA0040007' AND "Projected Rate Increase Type" = 'P';

SELECT * FROM public.udf_check_plans_upload() as Report;

SELECT public."udf_CalculateBaseRate"(null, 395.00, .05, 'C') as "BaseRate";

SELECT   "Hios Plan ID"
        ,"plan_year"
        ,"BaseRate"
        ,"Previous Year Base Rate"
        ,"Projected Rate Increase %"
        ,"Projected Rate Increase Type"
        ,public."udf_CalculateBaseRate"("BaseRate"
                                        ,"Previous Year Base Rate"
                                        ,"Projected Rate Increase %"
                                        ,"Projected Rate Increase Type") as "BaseRateNew"
SELECT *
FROM vw_stage_plans_raw;

BEGIN;
SELECT * From public.udf_update_plans('public.stage_plans_raw_2019planstest_20180815')
rollback;
-- commit

SELECT * FROM "Plans" WHERE "UpdatedDate" > (CURRENT_TIMESTAMP - interval '15 hours');
SELECT * FROM "Plans" WHERE "CreatedDate" > (CURRENT_TIMESTAMP - interval '10 mins');
SELECT * FROM "PlanRates" WHERE "UpdatedDate" > (CURRENT_TIMESTAMP - interval '15 hours');

SELECT * FROM "PlanRates" WHERE "UpdatedDate" > (CURRENT_TIMESTAMP - interval '15 hours') AND "BaseRate" IS NULL and "Year" = 2018;

SELECT * FROM "Plans" AS P
WHERE EXISTS (SELECT 1 FROM vw_stage_plans_raw S WHERE S."Hios Plan ID" = P."HiosPlanID" AND S."plan_year" = P."Year");

SELECT * FROM "PlanRates" PR WHERE EXISTS (SELECT 1 FROM vw_stage_plans_raw S WHERE S."Hios Plan ID" = PR."HiosPlanID" AND S."plan_year" = PR."Year")
AND EXISTS (SELECT 1 FROM "Plans" AS P WHERE PR."HiosPlanID" = P."HiosPlanID" AND PR."Year" = P."Year");

/*
DELETE FROM "Plans" WHERE "UpdatedDate" > (CURRENT_TIMESTAMP - interval '10 mins');
DELETE FROM "PlanRates" WHERE "UpdatedDate" > (CURRENT_TIMESTAMP - interval '15 mins');

BEGIN;

DELETE FROM "PlanRates" PR WHERE EXISTS (SELECT 1 FROM vw_stage_plans_raw S WHERE S."Hios Plan ID" = PR."HiosPlanID" AND S."plan_year" = PR."Year")
AND EXISTS (SELECT 1 FROM "Plans" AS P WHERE PR."HiosPlanID" = P."HiosPlanID" AND PR."Year" = P."Year");

DELETE FROM "Plans" P WHERE EXISTS (SELECT 1 FROM vw_stage_plans_raw S WHERE S."Hios Plan ID" = P."HiosPlanID" AND S."plan_year" = P."Year");

INSERT INTO "Plans"
SELECT * FROM "plans_bak_20180816005254";

INSERT INTO "PlanRates"
SELECT * FROM "planrates_bak_20180816005254";

-- COMMIT;
-- ROLLBACK;

*/

SELECT * FROM "Plans" WHERE "Year" = 2018 AND "State" = 'CA' AND "ServiceAreaID" = 'CAS001';
SELECT * FROM "Plans" WHERE "HiosPlanID" = '11721MS0120007';
SELECT * FROM vw_stage_plans_raw WHERE "Hios Plan ID" = '11721MS0120007' AND "plan_year" = 2019;
SELECT * FROM "PlanRates" WHERE "HiosPlanID" = '11721MS0120007' AND "Year" = 2019;

SELECT * FROM pg_catalog.pg_Tables WHERE tablename like '%bak%' and tablename like '%2018%';

BEGIN;
SELECT * FROM public.udf_update_plans('public.stage_plans_raw_testupload153806627_20180808')
ROLLBACK

SELECT * FROM public.stage_plans_raw_testupload153806627_20180808 WHERE "BaseRate" is null

SELECT * FROM "Plans" WHERE "HiosPlanID" = '15287RI1170002'

SELECT * FROM stage_plans_raw_2019planstest_20180815 WHERE "Hios Plan ID" = '15287RI1170002'

-- Compare a column in Plans, Stage Clean, vs Latest Backup
SELECT  P."HiosPlanID", P."Year", P."PlanStatus", P."IsActive" , SC."StageTableName"
        ,SC."PlanStatus"
        ,BAK."PlanStatus", BAK."IsActive" 
FROM    "Plans" AS P
INNER
JOIN    stage_plans_clean           as SC   ON  SC."HiosPlanID" = P."HiosPlanID"
                                            AND SC."Year" = P."Year"
INNER
JOIN    plans_bak_20180816003752    AS BAK  ON  BAK."HiosPlanID" = P."HiosPlanID"
                                            AND BAK."Year" = P."Year"
WHERE   1 = 1
--AND     P."UpdatedDate" > (CURRENT_TIMESTAMP - interval '15 hours') 
AND     P."PlanStatus" = 'T'
AND     SC."StageTableName" = 'public.stage_plans_raw_2019PlansTest_20180816';

/*
-- Update a column from backup, basically rolling back wrong updates
BEGIN;
UPDATE  "Plans" AS P
SET     "PlanStatus" = BAK."PlanStatus"
FROM    stage_plans_clean           as SC
INNER
JOIN    plans_bak_20180816003752    AS BAK  ON  BAK."HiosPlanID" = SC."HiosPlanID"
                                            AND BAK."Year" = SC."Year"
WHERE   1 = 1
AND     P."Year" = 2018
AND     SC."HiosPlanID" = P."HiosPlanID"
AND     SC."Year" = P."Year"
AND     COALESCE(P."PlanStatus", '-1') != COALESCE(BAK."PlanStatus", '-1')
AND     SC."StageTableName" = 'public.stage_plans_raw_2019PlansTest_20180816';
-- COMMIT
-- ROLLBACK
*/

-- Compare a column in PlanRates, Stage Clean, vs Latest Backup
SELECT  PR."HiosPlanID", PR."Year"
        ,PR."BaseRate" as "Cur.BaseRate"
        ,SC."StageTableName"
        ,SC."BaseRate" as "New.BaseRate"
        ,SC."IncreaseType"
        ,SC."ProjectedRateIncrease"
        ,BAK."BaseRate" as "Prev.BaseRate"
        ,SC."PlanStatus"
        ,PBAK."PlanStatus"
        ,PBAK."IsActive"
FROM    "PlanRates" AS PR
INNER
JOIN    stage_plans_clean           as SC   ON  SC."HiosPlanID" = PR."HiosPlanID"
                                            AND SC."Year" = PR."Year"
INNER
JOIN    planrates_bak_20180816003752    AS BAK  ON  BAK."HiosPlanID" = PR."HiosPlanID"
                                        AND BAK."Year" = PR."Year"
INNER
JOIN    plans_bak_20180816003752    AS PBAK  ON  PBAK."HiosPlanID" = PR."HiosPlanID"
                                            AND PBAK."Year" = PR."Year"
WHERE   1 = 1
--AND     P."UpdatedDate" > (CURRENT_TIMESTAMP - interval '15 hours') 
AND     PR."Year" = 2018
AND     ((PR."BaseRate" IS NULL AND BAK."BaseRate" IS NOT NULL) OR (PR."BaseRate" IS NOT NULL AND BAK."BaseRate" IS NULL) OR (PR."BaseRate" != BAK."BaseRate"))
AND     SC."StageTableName" = 'public.stage_plans_raw_2019PlansTest_20180816';

/*
BEGIN;
UPDATE  "PlanRates" AS PR
SET     "BaseRate" = BAK."BaseRate"
FROM    stage_plans_clean           as SC
INNER
JOIN    planrates_bak_20180816003752    AS BAK  ON  BAK."HiosPlanID" = SC."HiosPlanID"
                                        AND BAK."Year" = SC."Year"
INNER
JOIN    plans_bak_20180816003752    AS PBAK  ON  PBAK."HiosPlanID" = SC."HiosPlanID"
                                            AND PBAK."Year" = SC."Year"
WHERE   1 = 1
AND     SC."HiosPlanID" = PR."HiosPlanID"
AND     SC."Year" = PR."Year"
AND     PR."Year" = 2018
AND     ((PR."BaseRate" IS NULL AND BAK."BaseRate" IS NOT NULL) OR (PR."BaseRate" IS NOT NULL AND BAK."BaseRate" IS NULL) OR (PR."BaseRate" != BAK."BaseRate"))
AND     SC."StageTableName" = 'public.stage_plans_raw_2019PlansTest_20180816';
COMMIT;
*/