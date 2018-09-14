DROP FUNCTION IF EXISTS public.udf_Report_PlanBenefits(int, varchar(2));
CREATE OR REPLACE FUNCTION public.udf_Report_PlanBenefits(yearid int, stateAbbr varchar(2) default null) 
RETURNS SETOF vw_PlanBenefits AS $$

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
	p."GroupID" AS "ClusterID",
    null as "UpdatedDate"
FROM "Plans" as p
CROSS JOIN
        (
        SELECT DISTINCT "Benefit" FROM "PlanBenefits" 
        WHERE "Benefit"  NOT IN 
                                ( 'MentalHealthProfessionalOutpatient'
                                 ,'HabilitationServices'
                                 ,'OtherPractitionerOfficeVisit'
                                 ,'OutpatientRehabilitationServices'
                                 ,'PreventiveCare'
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