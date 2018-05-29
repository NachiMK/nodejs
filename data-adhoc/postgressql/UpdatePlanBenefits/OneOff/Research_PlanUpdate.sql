SELECT 
	"PlanBenefitID",
	p."Year",
	p."HiosPlanID",
	p."State",
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
	'' as "Notes",
	p."GroupID" AS "ClusterID"
	,pb."UpdatedDate"
	,p."UpdatedDate"
	,p."ServiceAreaID"
	,p."UseForModeling"
FROM "Plans" as p
LEFT
JOIN "PlanBenefits"  as pb ON p."HiosPlanID" = pb."HiosPlanID" 
                      AND p."Year" = pb."Year"
                      AND "Benefit"  NOT IN 
                        ( 'MentalHealthProfessionalOutpatient'
                         ,'HabilitationServices'
                         ,'OtherPractitionerOfficeVisit'
                         ,'OutpatientRehabilitationServices'
                         ,'PreventiveCare')
WHERE p."Year" = 2018 
AND p."IsForSale" = true 
AND p."State" = 'NM'
AND p."ServiceAreaID" = 'NMS001'
--AND p. "HiosPlanID" = '57173NM0200001'
--AND p."UseForModeling" = false
AND p."UpdatedDate" > '2018-04-25'
ORDER BY "State", "HiosPlanID", "Benefit";


SELECT * 
FROM "PlanRates" as pr
WHERE  1 = 1
--AND pr."State" = 'NM'
--AND pr."ServiceAreaID" = 'NMS0001'
AND   pr."HiosPlanID" = '57173NM0200001';

SELECT 'SELECT * FROM "'||tablename||'" WHERE "HiosPlanID" = ''57173NM0200001''; ' FROM pg_catalog.pg_tables where tablename like '%planbenefits%'
order by tablename;
