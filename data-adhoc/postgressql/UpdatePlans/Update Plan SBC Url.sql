-- Look at plans that we need to update....
SELECT  "HiosPlanID", "Year", "State", "BenefitsSummaryURL"
        , 'https://s3.amazonaws.com/prod-carrier-sbc-documents/' || CAST("Year" AS VARCHAR) || '/' || "State" || '/' || "HiosPlanID" || '.pdf' as "NewBenefitsSummaryURL"
FROM    "Plans"
WHERE   "BenefitsSummaryURL" IS NULL
--AND     "IsForSale" = TRUE
AND     "Year" = 2019;

-- Update the plans
UPDATE  "Plans"
SET     "BenefitsSummaryURL" = 'https://s3.amazonaws.com/prod-carrier-sbc-documents/' || CAST("Year" AS VARCHAR) || '/' || "State" || '/' || "HiosPlanID" || '.pdf'
WHERE   "BenefitsSummaryURL" IS NULL
--AND     "IsForSale" = TRUE
AND     "Year" = 2019;


-- Check whether we updated all, should return zero rows
SELECT  *
FROM    "Plans"
WHERE   "BenefitsSummaryURL" IS NULL
--AND     "IsForSale" = TRUE
AND     "Year" = 2019;

-- Look at plans that we need to update....
SELECT  "HiosPlanID", "Year", "State", "BenefitsSummaryURL"
        , 'https://s3.amazonaws.com/prod-carrier-sbc-documents/' || CAST("Year" AS VARCHAR) || '/' || "State" || '/' || "HiosPlanID" || '.pdf' as "NewBenefitsSummaryURL"
FROM    "Plans"
WHERE   "BenefitsSummaryURL" IS NOT NULL
--AND     "IsForSale" = TRUE
AND     "Year" = 2019
AND     "BenefitsSummaryURL" ~ '2018';


-- Update the plans
UPDATE  "Plans"
SET     "BenefitsSummaryURL" = 'https://s3.amazonaws.com/prod-carrier-sbc-documents/' || CAST("Year" AS VARCHAR) || '/' || "State" || '/' || "HiosPlanID" || '.pdf'
WHERE   "BenefitsSummaryURL" IS NOT NULL
AND     "Year" = 2019
AND     "BenefitsSummaryURL" ~ '2018';