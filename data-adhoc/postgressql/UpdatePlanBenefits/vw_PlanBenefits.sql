-- DROP VIEW IF EXISTS public.vw_PlanBenefits;
CREATE VIEW public.vw_PlanBenefits 
AS    
SELECT 
	"PlanBenefitID",
	"Plans"."Year",
	LEFT("Plans"."HiosPlanID", 5) as "HIOS",
	"Plans"."HiosPlanID",
	"Plans"."State",
	"PlanBenefits"."Benefit",
	PBL."Sort" as "sort",
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
	,"PlanBenefits"."UpdatedDate"
FROM "Plans"
INNER
JOIN "PlanBenefits" ON "Plans"."HiosPlanID" = "PlanBenefits"."HiosPlanID" 
                    AND "Plans"."Year" = "PlanBenefits"."Year"
INNER
JOIN  "PlanBenefitLookup" as PBL ON	 PBL."Year" = "PlanBenefits"."Year"
                        		 AND PBL."Benefit" = "PlanBenefits"."Benefit"
WHERE "Plans"."IsForSale" = true
AND	  PBL."ExcludeDuplicateBenefit" = false
;