SELECT * FROM "Plans"
WHERE NOT EXISTS
	(SELECT * FROM "PlanBenefits"
	 WHERE "PlanBenefits"."Benefit" = 'PreferredBrandDrugsMailOrder' AND "Plans"."HiosPlanID" = "PlanBenefits"."HiosPlanID" AND "Plans"."Year" = "PlanBenefits"."Year")
	 AND "Plans"."Year" = 2018
	 
	 
