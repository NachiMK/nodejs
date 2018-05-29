INSERT INTO "PlanBenefits"(
	"Year",
	"HiosPlanID",
	"Benefit",
	"ServiceNotCovered", 
	"AppliesToDeductible",
	"AppliesToMOOP",
	"Coinsurance",
	"CopayAmount",
	"CopayDayLimit",
	"CoinsuranceCopayOrder",
	"MemberServicePaidCap",
	"CoverageVisitLimit",
	"SBCImage",
	"SBCValue",
	"SBCCleanValue",
	"BenefitDisplayValue",
	"BenefitDisplayGroup",
	"IncludeInDetailSBC",
	"IncludeInBundleCard",
	"Sort",
	"Notes",
	"Status",
	"FirstDollarVisits",
	"IsGrouped",
	"TieredBenefit",
	"SeparatedBenefit",
	"CopayAfterFirstVisits",
	"UpdateDate",
	"CopayDays"
)
SELECT
	2018,			--Year
    "HiosPlanID",	--HiosPlanID
    'Telemedicine',	--Benefit
    false,			--ServiceNotCovered
    false,			--AppliesToDeductible
    false,			--AppliesToMOOP
    -1.0,			--Coinsurance
    -1.0,			--CopayAmount
    0,				--CopayDayLimit
    0,				--CoinsuranceCopayOrder
    0,				--MemberServicePaidCap
    0,				--CoverageVisitLimit
    null,			--SBCImage
    0,				--SBCValue
    '',				--SBCCleanValue
    '',				--BenefitDisplayValue
    '',				--BenefitDisplayGroup
    false,			--IncludeInDetailSBC
    false,			--IncludeInBundleCard
    0,				--Sort
    '',				--Notes
    'New',			--Status
    0,				--FirstDollarVisits
    false,			--IsGrouped
    0,				--TieredBenefit
    false,			--SeparatedBenefit
    0,				--CopayAfterFirstVisits
    NOW(),			--UpdateDate
	0				--CopayDays
FROM
    "Plans"
WHERE
    "Plans"."Year" = 2018 AND NOT EXISTS
	(SELECT 
	 	"PlanBenefitID"
	 FROM "PlanBenefits" 
	 WHERE  "PlanBenefits"."HiosPlanID" = "Plans"."HiosPlanID" 
	 	AND "PlanBenefits"."Year" = "Plans"."Year" 
	 	AND "PlanBenefits"."Benefit" = 'Telemedicine'
	)
	 
	 
	 
	 
	 
	 