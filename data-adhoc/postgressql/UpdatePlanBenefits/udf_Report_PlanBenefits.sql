DROP FUNCTION IF EXISTS public.udf_Report_PlanBenefits(int, varchar(2));
CREATE OR REPLACE FUNCTION public.udf_Report_PlanBenefits(yearid int, stateAbbr varchar(2) default null) 
RETURNS SETOF vw_PlanBenefits AS $$

-- Smaller Report by State
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
                      AND "PlanBenefits"."Benefit"  NOT IN 
                        ( 'MentalHealthProfessionalOutpatient'
                         ,'HabilitationServices'
                         ,'OtherPractitionerOfficeVisit'
                         ,'OutpatientRehabilitationServices'
                         ,'PreventiveCare')
INNER
JOIN  "PlanBenefitLookup" as PBL ON PBL."Year" = "PlanBenefits"."Year"
                                AND PBL."Benefit" = "PlanBenefits"."Benefit"
WHERE "Plans"."Year" = ($1) 
AND  (
        ("Plans"."State" = ($2) AND ($2) IS NOT NULL AND LENGTH(($2)) > 0) 
        OR 
        (($2) IS NULL OR LENGTH(($2)) = 0)
     )
AND  "Plans"."IsForSale" = true 

UNION ALL

-- Plans without benefits.
SELECT 
	CAST(-1 * ROW_NUMBER() OVER() as INT) as "PlanBenefitID",
	p."Year",
    LEFT(p."HiosPlanID", 5) as "HIOS",
	p."HiosPlanID",
	p."State",
	pb1."Benefit",
    pb1."Sort" as "sort",
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
	p."GroupID" AS "ClusterID",
    null as "UpdatedDate"
FROM "Plans" as p
CROSS JOIN
        (
        SELECT PBL."Benefit", PBL."Sort" 
        FROM public."PlanBenefitLookup" as PBL
        WHERE "ExcludeDuplicateBenefit" = false
        AND PBL."Year" = ($1)
        ) as pb1
WHERE NOT EXISTS (SELECT 1 FROM "PlanBenefits" as pb 
                  WHERE p."HiosPlanID" = pb."HiosPlanID" 
                  AND   p."Year" = pb."Year"
                  AND pb."Benefit"  NOT IN 
                                ( 'MentalHealthProfessionalOutpatient'
                                 ,'HabilitationServices'
                                 ,'OtherPractitionerOfficeVisit'
                                 ,'OutpatientRehabilitationServices'
                                 ,'PreventiveCare'
                                 )
                  )
AND p."Year" = ($1)
AND p."IsForSale" = true 
AND  (
        (p."State" = ($2) AND ($2) IS NOT NULL AND LENGTH(($2)) > 0) 
        OR 
        (($2) IS NULL OR LENGTH(($2)) = 0)
     )
--AND p."CreatedDate" is not null
ORDER BY "HiosPlanID", "Benefit";


$$ LANGUAGE SQL;
/*
    SELECT * FROM public.udf_Report_PlanBenefits(2019, 'NY')
    SELECT * FROM public.udf_Report_PlanBenefits(2019)
*/