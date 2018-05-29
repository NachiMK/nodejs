SELECT 
	"PlanBenefits"."PlanBenefitID",
	"PlanBenefits"."Year",
	"PlanBenefits"."HiosPlanID",
	"PlanBenefits"."Benefit",
	"PlanBenefits"."ServiceNotCovered",
	"PlanBenefits"."AppliesToDeductible",
	"PlanBenefits"."AppliesToMOOP",
	"PlanBenefits"."Coinsurance",
	"PlanBenefits"."CopayAmount",
	"PlanBenefits"."CopayDayLimit",
	"PlanBenefits"."CoinsuranceCopayOrder",
	"PlanBenefits"."MemberServicePaidCap",
	"PlanBenefits"."CoverageVisitLimit",
	"PlanBenefits"."SBCImage",
	"PlanBenefits"."SBCValue",
	"PlanBenefits"."SBCCleanValue",
	"PlanBenefits"."BenefitDisplayValue",
	"PlanBenefits"."BenefitDisplayGroup",
	"PlanBenefits"."IncludeInDetailSBC",
	"PlanBenefits"."IncludeInBundleCard",
	"PlanBenefits"."Sort",
	"PlanBenefits"."Notes",
	"PlanBenefits"."Status",
	"PlanBenefits"."FirstDollarVisits",
	"PlanBenefits"."IsGrouped",
	"PlanBenefits"."TieredBenefit",
	"PlanBenefits"."SeparatedBenefit",
	"PlanBenefits"."CopayAfterFirstVisits",
	"PlanBenefits"."UpdateDate",
	"PlanBenefits"."CopayDays",
	"PlanBenefits"."CreatedDate",
	"PlanBenefits"."UpdatedDate",
	"Plans"."GroupID" AS "ClusterID"
FROM "PlanBenefits" 
INNER JOIN "Plans" ON "Plans"."HiosPlanID" = "PlanBenefits"."HiosPlanID" AND "Plans"."Year" = "PlanBenefits"."Year"
WHERE "PlanBenefits"."Year" = 2018 AND "Plans"."IsForSale" = true 
AND    "Benefit"  NOT IN ('MentalHealthProfessionalOutpatient','HabilitationServices','OtherPractitionerOfficeVisit'
,'OutpatientRehabilitationServices','PreventiveCare')
ORDER BY "HiosPlanID", "Benefit";

-- Smaller Report by State
SELECT 
	"PlanBenefitID",
	"Plans"."Year",
	"Plans"."HiosPlanID",
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
	,"PlanBenefits"."UpdatedDate"
FROM "Plans"
INNER
JOIN "PlanBenefits" ON "Plans"."HiosPlanID" = "PlanBenefits"."HiosPlanID" 
                      AND "Plans"."Year" = "PlanBenefits"."Year"
                      AND "Benefit"  NOT IN 
                        ( 'MentalHealthProfessionalOutpatient'
                         ,'HabilitationServices'
                         ,'OtherPractitionerOfficeVisit'
                         ,'OutpatientRehabilitationServices'
                         ,'PreventiveCare')
WHERE "Plans"."Year" = 2018 
AND "Plans"."IsForSale" = true 
-- AND "Benefit" IN ('EmergencyRoomFacility', 'EmergencyRoomProfessional')
AND "Plans"."State" = 'MS'
ORDER BY "HiosPlanID", "Benefit";

--UNION ALL

-- Plans without benefits.
SELECT 
	null as "PlanBenefitID",
	p."Year",
	p."HiosPlanID",
	p."State",
	pb1."Benefit",
	null as "ServiceNotCovered",
	null as "AppliesToDeductible",
	null as "Coinsurance",
	null as "CopayAmount",
	null as "CopayDayLimit",
	null as "CoinsuranceCopayOrder",
	null as "MemberServicePaidCap",
	null as "CoverageVisitLimit",
	null as "FirstDollarVisits",
	null as "IsGrouped",
	null as "CopayAfterFirstVisits",
	null as "Notes",
	p."GroupID" AS "ClusterID"
FROM "Plans" as p
CROSS JOIN
        (
        SELECT DISTINCT "Benefit" FROM "PlanBenefits" 
        WHERE "Benefit"  NOT IN 
                                ( 'MentalHealthProfessionalOutpatient'
                                 ,'HabilitationServices'
                                 ,'OtherPractitionerOfficeVisit'
                                 ,'OutpatientRehabilitationServices'
                                 )

        ) as pb1
WHERE NOT EXISTS (SELECT 1 FROM "PlanBenefits" as pb 
                  WHERE p."HiosPlanID" = pb."HiosPlanID" 
                  AND   p."Year" = pb."Year"
                  AND pb."Benefit"  NOT IN 
                                ( 'MentalHealthProfessionalOutpatient'
                                 ,'HabilitationServices'
                                 ,'OtherPractitionerOfficeVisit'
                                 ,'OutpatientRehabilitationServices'
                                 )
                  )
AND p."Year" = 2018 
AND p."IsForSale" = true 
AND p."State" = 'MS'
--AND p."CreatedDate" is not null
ORDER BY "HiosPlanID", "Benefit";


-- Report of recently modified data.
SELECT 
	"PlanBenefitID",
	"Plans"."Year",
	"Plans"."HiosPlanID",
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
	,"PlanBenefits"."UpdatedDate"
FROM "Plans"
INNER
JOIN "PlanBenefits" ON "Plans"."HiosPlanID" = "PlanBenefits"."HiosPlanID" 
                      AND "Plans"."Year" = "PlanBenefits"."Year"
                      AND "Benefit"  NOT IN 
                        ( 'MentalHealthProfessionalOutpatient'
                         ,'HabilitationServices'
                         ,'OtherPractitionerOfficeVisit'
                         ,'OutpatientRehabilitationServices'
                         ,'PreventiveCare')
WHERE "Plans"."Year" = 2018 
AND "Plans"."IsForSale" = true 
AND  EXISTS (SELECT 1 FROM vw_stage_planbenefits as v WHERE v."PlanBenefitID" = "PlanBenefits"."PlanBenefitID")
ORDER BY "HiosPlanID", "Benefit";
