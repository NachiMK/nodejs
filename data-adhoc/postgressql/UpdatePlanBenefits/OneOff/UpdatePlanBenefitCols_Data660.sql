BEGIN;

CREATE TABLE public."PlanBenefits_Data660_BAK" AS 
SELECT  PB."PlanBenefitID", PB."Benefit", "AppliesToMOOP", "SBCValue" ,"SBCCleanValue"
        ,"BenefitDisplayValue" ,"BenefitDisplayGroup"
        ,'Existing' AS "PlanType", PB."Year", PB."HiosPlanID"
FROM    "PlanBenefits" PB
INNER
JOIN    "PlanBenefitLookup" PBL ON PBL."Benefit" = PB."Benefit" AND PBL."Year" = PB."Year"
INNER
JOIN    "Plans" AS P ON P."Year" = PB."Year" AND PB."HiosPlanID" = P."HiosPlanID" 
                                             AND P."IsForSale" = true
WHERE   1 = 1
and     PB."Year" = 2019
--AND     PBL."Sort" > 0
AND     EXISTS (SELECT 1 FROM "Plans" AS P8 WHERE P8."Year" = 2018 AND P8."HiosPlanID" = P."HiosPlanID")
AND     (
               "AppliesToMOOP" IS NULL
            OR "SBCValue" IS NULL
            OR "SBCCleanValue" IS NULL
            OR "BenefitDisplayValue" IS NULL
            OR "BenefitDisplayGroup" IS NULL
        )
UNION 

SELECT  PB."PlanBenefitID", PB."Benefit", "AppliesToMOOP", "SBCValue" ,"SBCCleanValue"
        ,"BenefitDisplayValue" ,"BenefitDisplayGroup"
        ,'New' AS "PlanType", PB."Year", PB."HiosPlanID"
FROM    "PlanBenefits" PB
INNER
JOIN    "PlanBenefitLookup" PBL ON PBL."Benefit" = PB."Benefit" AND PBL."Year" = PB."Year"
INNER
JOIN    "Plans" AS P ON P."Year" = PB."Year" AND PB."HiosPlanID" = P."HiosPlanID" 
                                             AND P."IsForSale" = true
WHERE   1 = 1
and     PB."Year" = 2019
--AND     PBL."Sort" > 0
AND     NOT EXISTS (SELECT 1 FROM "Plans" AS P8 WHERE P8."Year" = 2018 AND P8."HiosPlanID" = P."HiosPlanID");

COMMIT

-- UPDATE
BEGIN;
UPDATE  "PlanBenefits" AS PB
SET      "AppliesToMOOP" = CASE WHEN PB."AppliesToMOOP" IS NULL
                                THEN CASE WHEN PB."Benefit" = 'PreventiveCare' THEN FALSE ELSE TRUE END
                                ELSE PB."AppliesToMOOP"
                           END
        ,"SBCValue" = COALESCE(PB."SBCValue", '')
        ,"SBCCleanValue" = COALESCE(PB."SBCCleanValue", '')
        ,"BenefitDisplayValue" = COALESCE(PB."BenefitDisplayValue", '')
        ,"BenefitDisplayGroup" = COALESCE(PB."BenefitDisplayGroup", '')
FROM    public."PlanBenefits_Data660_BAK" AS S
WHERE   S."PlanBenefitID" = PB."PlanBenefitID"
AND     S."Year" = PB."Year"
AND     S."HiosPlanID" = PB."HiosPlanID"
AND     PB."Year" = 2019
--AND     S."PlanBenefitID" = 513581 --DEV:511479;
COMMIT;

-- Verify after update -- Should get zero rows.
SELECT  PB."PlanBenefitID", PB."Benefit", "AppliesToMOOP", "SBCValue" ,"SBCCleanValue"
        ,"BenefitDisplayValue" ,"BenefitDisplayGroup"
        ,'New' AS "PlanType", PB."Year", PB."HiosPlanID"
FROM    "PlanBenefits" PB
WHERE   1 = 1
and     PB."Year" = 2019
AND     EXISTS (SELECT 1 FROM public."PlanBenefits_Data660_BAK" AS S WHERE S."PlanBenefitID" = PB."PlanBenefitID")
--AND     PB."PlanBenefitID" = 513581 --DEV:511479
AND     (
               "AppliesToMOOP" IS NULL
            OR "SBCValue" IS NULL
            OR "SBCCleanValue" IS NULL
            OR "BenefitDisplayValue" IS NULL
            OR "BenefitDisplayGroup" IS NULL
        )
;

SELECT * FROM "PlanBenefits_Data619_BAK"

SELECT * FROM "PlanRates" WHERE "HiosPlanID" = '99110CA0400065';

SELECT * FROM "Plans" AS P
INNER
JOIN "PlanBenefits" AS PB ON PB."Year" = P."Year" AND PB."HiosPlanID" = P."HiosPlanID"
INNER
JOIN "PlanRates" AS PR ON PR."Year" = P."Year" AND PR."HiosPlanID" = P."HiosPlanID"
WHERE P."HiosPlanID" = '99110CA0400065';
