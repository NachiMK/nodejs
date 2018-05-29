BEGIN;

SELECT  COUNT(*) AS "PlanCountToUpdate_BeforeUpdate"
FROM   "Plans"
WHERE   "PlanDisplayName" != "CarrierFriendlyName" || ' ' || "PlanType";


CREATE TABLE IF NOT EXISTS "Plans_PlanDisplayName_BAK" AS 
SELECT "HiosPlanID", "State", "Year", "PlanDisplayName", "CarrierFriendlyName" || ' ' || "PlanType" as "NewPlanDisplayName"
FROM   "Plans"
WHERE  1 = 0
WITH NO DATA;

INSERT INTO "Plans_PlanDisplayName_BAK"
SELECT "HiosPlanID", "State", "Year", "PlanDisplayName", "CarrierFriendlyName" || ' ' || "PlanType" as "NewPlanDisplayName"
FROM   "Plans"
WHERE   "PlanDisplayName" != "CarrierFriendlyName" || ' ' || "PlanType";

UPDATE "Plans"
SET     "PlanDisplayName" = "CarrierFriendlyName" || ' ' || "PlanType"
        ,"UpdatedDate" = CURRENT_TIMESTAMP
WHERE   "PlanDisplayName" != "CarrierFriendlyName" || ' ' || "PlanType";

SELECT  COUNT(*) AS "PlanCountToUpdate_AfterUpdate"
FROM   "Plans"
WHERE   "PlanDisplayName" != "CarrierFriendlyName" || ' ' || "PlanType";

-- COMMIT;
-- ROLLBACK;