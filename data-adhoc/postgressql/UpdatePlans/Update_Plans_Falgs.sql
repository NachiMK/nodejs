-- One off updates to Plans Table.
CREATE TABLE IF NOT EXISTS public.stage_data521_PlanCorrections
(
     "Year"                 INT         NOT NULL
    ,"State"                VARCHAR(4)  NOT NULL
    ,"HiosPlanID"           VARCHAR(20) NOT NULL
    ,"HSA"                  VARCHAR(10)
    ,"use_for_modeling"     VARCHAR(10)
    ,"is_for_sale"          VARCHAR(10)
    ,"PlanMarketingName"    VARCHAR(200)
    ,"plan_type"            VARCHAR(20)
);

-- Load table with data from CSV using below command
-- psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_prod -c "\copy public.stage_data521_plancorrections from Plans_Update_Combined.csv WITH DELIMITER ',' null as '' CSV"

SELECT * FROM stage_data521_PlanCorrections;
UPDATE stage_data521_PlanCorrections set "HSA" = 'FALSE' WHERE "HSA" is null;
UPDATE stage_data521_PlanCorrections set "HSA" = 'FALSE' WHERE LENGTH(TRIM("HSA")) = 0;
UPDATE stage_data521_PlanCorrections set "HSA" = 'TRUE'  WHERE UPPER("HSA") = 'X';

UPDATE stage_data521_PlanCorrections set "is_for_sale" = 'FALSE' WHERE "is_for_sale" is null;
UPDATE stage_data521_PlanCorrections set "is_for_sale" = 'FALSE' WHERE LENGTH(TRIM("is_for_sale")) = 0;
UPDATE stage_data521_PlanCorrections set "is_for_sale" = 'TRUE'  WHERE UPPER("is_for_sale") = 'X';

UPDATE stage_data521_PlanCorrections set "use_for_modeling" = 'FALSE' WHERE "use_for_modeling" is null;
UPDATE stage_data521_PlanCorrections set "use_for_modeling" = 'FALSE' WHERE LENGTH(TRIM("use_for_modeling")) = 0;
UPDATE stage_data521_PlanCorrections set "use_for_modeling" = 'TRUE'  WHERE UPPER("use_for_modeling") = 'X';

SELECT * FROM stage_data521_PlanCorrections ORDER BY "Year", "State", "HiosPlanID";

-- Update Plan Marketing Name
SELECT  stg."HiosPlanID", stg."State", stg."Year", P."PlanID", stg."PlanMarketingName" as "PlanMarketingName_NewValue", P."PlanMarketingName" as "OldValue"
FROM    "Plans" AS P
INNER
JOIN    stage_data521_PlanCorrections   stg ON  stg."HiosPlanID" = P."HiosPlanID"
                                            AND stg."State"      = P."State"
                                            AND stg."Year"       = P."Year"
WHERE   stg."PlanMarketingName" is not null
AND     stg."PlanMarketingName" != P."PlanMarketingName";

-- Update Plan Type
SELECT  stg."HiosPlanID", stg."State", stg."Year", P."PlanID", "plan_type" as "PlanType_NewValue",  "PlanType" as "OldValue"
FROM    "Plans" AS P
INNER
JOIN    stage_data521_PlanCorrections   stg ON  stg."HiosPlanID" = P."HiosPlanID"
                                            AND stg."State"      = P."State"
                                            AND stg."Year"       = P."Year"
WHERE   stg."plan_type" is not null
AND     stg."plan_type" != P."PlanType";

-- Update HSA
SELECT  stg."HiosPlanID", stg."State", stg."Year", P."PlanID", CAST(stg."HSA" AS BOOLEAN) AS "HSA_NewValue", "IsHSA" as "OldValue"
FROM    "Plans" AS P
INNER
JOIN    stage_data521_PlanCorrections   stg ON  stg."HiosPlanID" = P."HiosPlanID"
                                            AND stg."State"      = P."State"
                                            AND stg."Year"       = P."Year"
WHERE   CAST(stg."HSA" AS BOOLEAN) != P."IsHSA";


-- Update use_for_modeling
SELECT  stg."HiosPlanID", stg."State", stg."Year", P."PlanID", CAST(stg."use_for_modeling" AS BOOLEAN) AS "use_for_modeling_NewValue", "UseForModeling" as "OldValue"
FROM    "Plans" AS P
INNER
JOIN    stage_data521_PlanCorrections   stg ON  stg."HiosPlanID" = P."HiosPlanID"
                                            AND stg."State"      = P."State"
                                            AND stg."Year"       = P."Year"
WHERE   CAST(stg."use_for_modeling" AS BOOLEAN) != P."UseForModeling";


-- Update is_for_sale
SELECT  stg."HiosPlanID", stg."State", stg."Year", P."PlanID", CAST(stg."is_for_sale" AS BOOLEAN) AS "is_for_sale_NewValue", "IsForSale" as "OldValue"
FROM    "Plans" AS P
INNER
JOIN    stage_data521_PlanCorrections   stg ON  stg."HiosPlanID" = P."HiosPlanID"
                                            AND stg."State"      = P."State"
                                            AND stg."Year"       = P."Year"
WHERE   CAST(stg."is_for_sale" AS BOOLEAN) != P."IsForSale";

BEGIN;

--Update Plan Marketing Name
UPDATE  "Plans" AS P
SET     "PlanMarketingName" = stg."PlanMarketingName", "UpdatedDate" = CURRENT_TIMESTAMP
FROM    stage_data521_PlanCorrections   stg 
WHERE   stg."HiosPlanID" = P."HiosPlanID"
AND     stg."State"      = P."State"
AND     stg."Year"       = P."Year"
AND     stg."PlanMarketingName" is not null
AND     stg."PlanMarketingName" != P."PlanMarketingName";

--Update PlanType
UPDATE  "Plans" AS P
SET     "PlanType" = stg."plan_type", "UpdatedDate" = CURRENT_TIMESTAMP
FROM    stage_data521_PlanCorrections   stg 
WHERE   stg."HiosPlanID" = P."HiosPlanID"
AND     stg."State"      = P."State"
AND     stg."Year"       = P."Year"
AND     stg."plan_type" is not null
AND     stg."plan_type" != P."PlanType";

--Update HSA
UPDATE  "Plans" AS P
SET     "IsHSA" = CAST(stg."HSA" AS BOOLEAN), "UpdatedDate" = CURRENT_TIMESTAMP
FROM    stage_data521_PlanCorrections   stg 
WHERE   stg."HiosPlanID" = P."HiosPlanID"
AND     stg."State"      = P."State"
AND     stg."Year"       = P."Year"
AND     CAST(stg."HSA" AS BOOLEAN) != P."IsHSA";

--Update use_for_modeling
UPDATE  "Plans" AS P
SET     "UseForModeling" = CAST(stg."use_for_modeling" AS BOOLEAN), "UpdatedDate" = CURRENT_TIMESTAMP
FROM    stage_data521_PlanCorrections   stg 
WHERE   stg."HiosPlanID" = P."HiosPlanID"
AND     stg."State"      = P."State"
AND     stg."Year"       = P."Year"
AND     CAST(stg."use_for_modeling" AS BOOLEAN) != P."UseForModeling";

-- Update is_for_sale
UPDATE  "Plans" AS P
SET     "IsForSale" = CAST(stg."is_for_sale" AS BOOLEAN), "UpdatedDate" = CURRENT_TIMESTAMP
FROM    stage_data521_PlanCorrections   stg 
WHERE   stg."HiosPlanID" = P."HiosPlanID"
AND     stg."State"      = P."State"
AND     stg."Year"       = P."Year"
AND     CAST(stg."is_for_sale" AS BOOLEAN) != P."IsForSale";


-- COMMIT;

-- ROLLBACK;

-- Check Counts again.