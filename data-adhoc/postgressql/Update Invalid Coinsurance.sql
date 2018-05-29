-- This script finds all Plans with Coinsurance greater than 1 and updates it to percent.
SELECT 
	"PlanBenefitID",
	pb."Year",
	pb."HiosPlanID",
	"Plans"."State",
	"Benefit",
	"ServiceNotCovered",
	"AppliesToDeductible",
	"Coinsurance",
	"CopayAmount",
	"CopayDayLimit",
	"CoinsuranceCopayOrder",
	"MemberServicePaidCap",
	"CoverageVisitLimit",
	"FirstDollarVisits",
	"IsGrouped",
	"CopayAfterFirstVisits",
	"Notes",
	"Plans"."GroupID" AS "ClusterID"
FROM "PlanBenefits" as pb
INNER JOIN "Plans" ON "Plans"."HiosPlanID" = pb."HiosPlanID" AND "Plans"."Year" = pb."Year"
WHERE pb."Year" = 2018 
AND "Plans"."IsForSale" = true 
AND pb."Coinsurance" > 1.0
AND pb."Coinsurance" is not null;

BEGIN;

UPDATE "PlanBenefits" as pb
SET    "Coinsurance" = "Coinsurance"/100.0, "UpdatedDate" = current_timestamp
FROM   "Plans"
WHERE  "Plans"."HiosPlanID" = pb."HiosPlanID" AND "Plans"."Year" = pb."Year"
AND    pb."Year" = 2018 
AND    "Plans"."IsForSale" = true 
AND    pb."Coinsurance" > 1.0
AND    pb."Coinsurance" is not null;

COMMIT;


SELECT * 
FROM "PlanBenefits" as pb
INNER JOIN "Plans" ON "Plans"."HiosPlanID" = pb."HiosPlanID" AND "Plans"."Year" = pb."Year"
WHERE pb."Year" = 2018 
AND "Plans"."IsForSale" = true 
AND pb."HiosPlanID" = '27603CA1500009'
AND pb."UpdatedDate" is not null;
