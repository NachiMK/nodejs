SELECT t1."HiosPlanID", t1."Benefit", t1."CopayAmount", t2."Benefit", t2."CopayAmount"
FROM "PlanBenefits" as t1
INNER JOIN "PlanBenefits" as t2 ON t1."Year" = t2."Year" AND t1."HiosPlanID" = t2."HiosPlanID"
WHERE t1."Benefit" IN ('NonPreferredBrandDrugs') AND t2."Benefit" IN ('PreferredBrandDrugs')
AND t1."Year" = 2018 ORDER BY t1."HiosPlanID", t1."Benefit"
