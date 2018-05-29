For FamilyMedicalDeductible: If CopayAmount = null or -1 then use IndividualMedicalDeductible CopayAmount * 2
	
For FamilyOutOfPocketMax: If CopayAmount = null or -1 then use IndividualOutOfPocketMax CopayAmount * 2

SELECT t1."HiosPlanID", t1."Benefit", t1."CopayAmount", t2."Benefit", t2."CopayAmount"
FROM "PlanBenefits" AS t1
INNER JOIN "PlanBenefits" AS t2 ON t1."Year" = t2."Year" AND t1."HiosPlanID" = t2."HiosPlanID"
INNER JOIN "Plans" AS p ON p."Year" = t1."Year" AND p."HiosPlanID" = t1."HiosPlanID"
WHERE t1."Benefit" = 'FamilyMedicalDeductible' AND t2."Benefit" = 'IndividualMedicalDeductible' AND t1."Year" = 2018 AND t1."CopayAmount" = -1 AND t2."CopayAmount" > 0 AND p."IsForSale" = true
ORDER BY t1."HiosPlanID", t1."Benefit"

