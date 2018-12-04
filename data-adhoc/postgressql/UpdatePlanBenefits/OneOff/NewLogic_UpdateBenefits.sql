-- DROP TABLE IF EXISTS public."_NM_FixPBDisplayValue";

CREATE TABLE public."_NM_FixPBDisplayValue" AS 
SELECT 
	PB."PlanBenefitID",
	P."Year",
    LEFT(P."HiosPlanID", 5) as "HIOS",
	P."HiosPlanID",
	P."State",
	PB."Benefit",
    PBL."Sort" as "sort",
	PB."ServiceNotCovered",
	PB."AppliesToDeductible",
	PB."Coinsurance",
	PB."CopayAmount",
	PB."CopayDayLimit",
	PB."CoinsuranceCopayOrder",
	PB."MemberServicePaidCap",
	PB."CoverageVisitLimit",
	PB."FirstDollarVisits",
	PB."IsGrouped",
	PB."CopayAfterFirstVisits",
	'' as "Notes",
	P."GroupID" AS "ClusterID",
	COALESCE(PB."BenefitDisplayValue", '') as "BenefitDisplayValue",
	COALESCE(PB."BenefitDisplayGroup", '') as "BenefitDisplayGroup",
	COALESCE(PB8."BenefitDisplayValue", '') as "BenefitDisplayValue2018",
	COALESCE(PB8."BenefitDisplayGroup", '') as "BenefitDisplayGroup2018",
    CAST('' AS VARCHAR) AS "NewBenefitDisplayValue",
	CAST('' AS VARCHAR) as "NewBenefitDisplayGroup",
	CAST('' AS TEXT) AS "LogicSteps",
	CASE WHEN PB."Benefit" IN ('IndividualMedicalDeductible', 'FamilyMedicalDeductible', 
                                'IndividualOutOfPocketMax', 'FamilyOutOfPocketMax', 
                                'IndividualDrugDeductible', 'FamilyDrugDeductible') THEN TRUE ELSE FALSE END AS "DedCalc"
FROM "Plans" as P
INNER
JOIN "PlanBenefits" as PB ON P."HiosPlanID" = PB."HiosPlanID" 
                      AND P."Year" = PB."Year"
INNER
JOIN "PlanBenefitLookup" as PBL ON PBL."Year" = PB."Year" AND PBL."Benefit" = PB."Benefit"
LEFT
JOIN "PlanBenefits" as PB8 ON PB."HiosPlanID" = PB8."HiosPlanID" 
                          AND PB."Benefit" = PB8."Benefit"
                          AND PB8."Year" = 2018
WHERE PBL."Sort" > -1
AND   P."Year" = 2019
AND   P."IsForSale" = true
AND     EXISTS (SELECT 1 FROM "Plans" AS P8 WHERE P8."Year" = 2018 
                AND P8."HiosPlanID" = P."HiosPlanID" AND P8."IsForSale" = true)
ORDER BY P."State", P."HiosPlanID", PBL."Sort"
;
CREATE INDEX IDX_ServiceCovered_Temp ON "_NM_FixPBDisplayValue" ("ServiceNotCovered");
CREATE INDEX IDX_BenefitDisplayValue_Temp ON "_NM_FixPBDisplayValue" ("BenefitDisplayValue");
CREATE INDEX IDX_DedCalc_Temp ON "_NM_FixPBDisplayValue" ("DedCalc");

-- Service not covered.
UPDATE "_NM_FixPBDisplayValue" AS N
SET    "NewBenefitDisplayValue" = CAST('Not Covered' as VARCHAR)
       ,"LogicSteps" = '000.ServiceNotCovered'
WHERE  N."NewBenefitDisplayValue" = CAST('' as VARCHAR)
AND    N."ServiceNotCovered" = TRUE;

-- Update Deductible values
UPDATE "_NM_FixPBDisplayValue" AS N
SET     "LogicSteps" = "LogicSteps" || '001.Deductible Calculation'
        ,"NewBenefitDisplayValue" = CASE WHEN "CopayAmount" IS NULL OR "CopayAmount" < 0 
                                         THEN 'Applies To Medical Deductible' 
                                         ELSE REPLACE(CAST(CAST(ROUND("CopayAmount") as money) AS VARCHAR), '.00', '') 
                                    END
WHERE   N."DedCalc" = TRUE
AND     N."ServiceNotCovered" = FALSE
AND     "LogicSteps" !~ '001.Deductible Calculation';

-- First Dollar visits
UPDATE "_NM_FixPBDisplayValue" AS N
SET     "LogicSteps" = "LogicSteps" || '001.FirstVisits'
        ,"NewBenefitDisplayValue" = REPLACE(CAST(CAST(ROUND("CopayAmount") as money) AS VARCHAR), '.00', '') || ' (visits 1 - ' || CAST("FirstDollarVisits" AS VARCHAR) || ')'
WHERE   N."DedCalc" = FALSE
AND     N."ServiceNotCovered" = FALSE
AND     N."FirstDollarVisits" IS NOT NULL
AND     N."FirstDollarVisits" != -1
AND     N."CopayAmount" is not null AND N."CopayAmount" != -1
AND     "LogicSteps" !~ '001.FirstVisits';

-- Copay/Coinsurance or both after First Dollar Visits
UPDATE "_NM_FixPBDisplayValue" AS N
SET     "LogicSteps" = "LogicSteps" || '->002.AfterFirstVists'
        ,"NewBenefitDisplayValue" = "NewBenefitDisplayValue" || 
        CASE WHEN "CoinsuranceCopayOrder" IS NOT NULL 
             AND  "CoinsuranceCopayOrder" IN ('Copay+Coinsurance', 'Copay/Coins') 
             THEN 
                CASE WHEN ("CopayAfterFirstVisits" > 0) AND ("Coinsurance" > 0)
                        THEN '; $' || REPLACE(CAST("CopayAfterFirstVisits" AS VARCHAR), '.00', '') || ' + ' 
                                  || CAST(ROUND("Coinsurance" * 100) AS VARCHAR) || '% '
                     WHEN  ("CopayAfterFirstVisits" >= 0)
                        THEN 
                            CASE WHEN "CopayAfterFirstVisits" = 0 
                                 THEN '; $0'
                                 ELSE '; $' || REPLACE(CAST("CopayAfterFirstVisits" AS VARCHAR), '.00', '')
                            END
                     WHEN  ("Coinsurance" >= 0)
                        THEN
                            CASE WHEN "Coinsurance" = 0 
                                 THEN ''
                                 ELSE '; ' || CAST(ROUND("Coinsurance" * 100) AS VARCHAR) || '%'
                            END
                     ELSE  ''
                 END
             ELSE
                CASE WHEN  ("CopayAfterFirstVisits" >= 0)
                        THEN 
                            CASE WHEN "CopayAfterFirstVisits" = 0 
                                 THEN '; $0'
                                 ELSE '; $' || REPLACE(CAST("CopayAfterFirstVisits" AS VARCHAR), '.00', '')
                            END
                     WHEN  ("Coinsurance" >= 0)
                        THEN
                            CASE WHEN "Coinsurance" = 0 
                                 THEN ''
                                 ELSE '; ' || CAST(ROUND("Coinsurance" * 100) AS VARCHAR) || '%'
                            END
                     ELSE  ''
                 END
        END
WHERE   N."DedCalc" = FALSE
AND     N."ServiceNotCovered" = FALSE
AND     N."FirstDollarVisits" IS NOT NULL
AND     N."FirstDollarVisits" != -1
AND     (N."CopayAfterFirstVisits" >= 0 OR N."Coinsurance" >= 0)
AND     "LogicSteps" !~ '->002.AfterFirstVists';

-- Copay/Coinsurance or both after First Dollar Visits
UPDATE "_NM_FixPBDisplayValue" AS N
SET     "LogicSteps" = "LogicSteps" || '->003.Copay/Coins'
        ,"NewBenefitDisplayValue" = "NewBenefitDisplayValue" || 
        CASE WHEN "CoinsuranceCopayOrder" IS NOT NULL 
             AND  "CoinsuranceCopayOrder" IN ('Copay+Coinsurance', 'Copay/Coins') 
             THEN 
                CASE WHEN ("CopayAmount" > 0) AND ("Coinsurance" > 0)
                        THEN '' || REPLACE(CAST(CAST("CopayAmount" AS MONEY) AS VARCHAR), '.00', '') || ' + ' 
                                || CAST(ROUND("Coinsurance" * 100) AS VARCHAR) || '%'
                     WHEN  ("CopayAmount" >= 0)
                        THEN 
                            CASE WHEN "CopayAfterFirstVisits" = 0 
                                 THEN '$0'
                                 ELSE '' || REPLACE(CAST(CAST("CopayAmount" AS MONEY) AS VARCHAR), '.00', '')
                            END
                     WHEN  ("Coinsurance" >= 0)
                        THEN
                            CASE WHEN "Coinsurance" = 0 
                                 THEN ''
                                 ELSE '' || CAST(ROUND("Coinsurance" * 100) AS VARCHAR) || '%'
                            END
                     ELSE  ''
                 END
             ELSE
                CASE WHEN  ("CopayAmount" >= 0)
                        THEN 
                            CASE WHEN "CopayAmount" = 0
                                 THEN '$0'
                                 ELSE '' || REPLACE(CAST(CAST("CopayAmount" AS MONEY) AS VARCHAR), '.00', '')
                            END
                     WHEN  ("Coinsurance" >= 0)
                        THEN
                            CASE WHEN "Coinsurance" = 0 
                                 THEN ''
                                 ELSE '' || CAST(ROUND("Coinsurance" * 100) AS VARCHAR) || '%'
                            END
                     ELSE  ''
                 END
        END
WHERE   N."DedCalc" = FALSE
AND     N."ServiceNotCovered" = FALSE
AND     (N."FirstDollarVisits" IS NULL OR N."FirstDollarVisits" = -1)
AND     (N."CopayAmount" >= 0 OR N."Coinsurance" >= 0)
AND     "LogicSteps" !~ '->003.Copay/Coins';

-- Max amount per year
UPDATE "_NM_FixPBDisplayValue" AS N
SET     "LogicSteps" = "LogicSteps" || '->004.MaxPerYear'
        ,"NewBenefitDisplayValue" = "NewBenefitDisplayValue" || ' up to ' || REPLACE(CAST(CAST(N."MemberServicePaidCap"  AS MONEY) AS VARCHAR), '.00', '')
WHERE   N."DedCalc" = FALSE
AND     N."ServiceNotCovered" = FALSE
AND     N."MemberServicePaidCap" IS NOT NULL
AND     N."MemberServicePaidCap" > 0
AND     (N."CopayAmount" >= 0 OR N."Coinsurance" >= 0)
AND     "LogicSteps" !~ '->004.MaxPerYear';

-- Max number of visits per year
UPDATE "_NM_FixPBDisplayValue" AS N
SET     "LogicSteps" = "LogicSteps" || '->005.MaxVisitsPerYear'
        ,"NewBenefitDisplayValue" = "NewBenefitDisplayValue" || '; ' || CAST(ROUND(N."CoverageVisitLimit") AS VARCHAR) || 
            CASE WHEN ROUND(N."CoverageVisitLimit") <= 1 THEN ' visit/year' ELSE ' visits/year' END
WHERE   N."DedCalc" = FALSE
AND     N."ServiceNotCovered" = FALSE
AND     N."CoverageVisitLimit" IS NOT NULL
AND     N."CoverageVisitLimit" > 0
AND     (N."CopayAmount" >= 0 OR N."Coinsurance" >= 0)
AND     "LogicSteps" !~ '->005.MaxVisitsPerYear';

UPDATE "_NM_FixPBDisplayValue" AS N
SET     "LogicSteps" = "LogicSteps" || '->010.RemoveFirstSemi'
        ,"NewBenefitDisplayValue" = SUBSTRING("NewBenefitDisplayValue" from 3)
WHERE   "NewBenefitDisplayValue" IS NOT NULL
AND LENGTH("NewBenefitDisplayValue") > 2
AND LEFT("NewBenefitDisplayValue", 2) = '; ';


-- Benefit Display group
UPDATE "_NM_FixPBDisplayValue" AS N
SET    "NewBenefitDisplayGroup" = BG2."BenefitDisplayGroup"
FROM  "BenefitGenerator2" BG2
WHERE  BG2."Benefit" = N."Benefit"
AND    N."NewBenefitDisplayGroup" = '';

SELECT * FROM "_NM_FixPBDisplayValue" WHERE "LogicSteps" ~ '005.MaxVisitsPerYear';

SELECT "LogicSteps", COUNT(*) AS Cnt
FROM "_NM_FixPBDisplayValue" WHERE "NewBenefitDisplayValue" != CAST('' as VARCHAR)
GROUP BY "LogicSteps";

-- REPORT
SELECT * FROM "_NM_FixPBDisplayValue" 
ORDER BY "Year", "State", "HiosPlanID", "sort";

-- Checkk
SELECT "HiosPlanID", "Benefit", "sort", "BenefitDisplayValue2018",  "NewBenefitDisplayValue", "BenefitDisplayValue"
FROM "_NM_FixPBDisplayValue" 
--WHERE "HiosPlanID" = '10544CA0080001' 
WHERE "HiosPlanID" IN ('36046MA0690999', '59763MA0030009', '42690MA1390006')
Order by "HiosPlanID", "sort";

BEGIN;

UPDATE "PlanBenefits" AS PB
SET    "BenefitDisplayValue" = S."NewBenefitDisplayValue"
FROM   "_NM_FixPBDisplayValue" AS S
WHERE   S."PlanBenefitID" = PB."PlanBenefitID"
AND     (
            (PB."BenefitDisplayValue" IS NULL AND S."NewBenefitDisplayValue" IS NOT NULL)
        OR  (PB."BenefitDisplayValue" IS NOT NULL AND S."NewBenefitDisplayValue" != PB."BenefitDisplayValue")
        )
AND     S."HiosPlanID" IN ('36046MA0690999', '59763MA0030009', '42690MA1390006');

UPDATE "PlanBenefits" AS PB
SET    "BenefitDisplayGroup" = S."NewBenefitDisplayGroup"
FROM   "_NM_FixPBDisplayValue" AS S
WHERE   S."PlanBenefitID" = PB."PlanBenefitID"
AND     (
            (PB."BenefitDisplayGroup" IS NULL AND S."NewBenefitDisplayGroup" IS NOT NULL)
        OR  (PB."BenefitDisplayGroup" IS NOT NULL AND S."NewBenefitDisplayGroup" != PB."BenefitDisplayGroup")
        )
AND     S."HiosPlanID" IN ('36046MA0690999', '59763MA0030009', '42690MA1390006');

SELECT  PB."PlanBenefitID", PB."BenefitDisplayValue", S."NewBenefitDisplayValue"
FROM   "PlanBenefits" AS PB, "_NM_FixPBDisplayValue" AS S
WHERE   S."PlanBenefitID" = PB."PlanBenefitID"
AND     (
            (PB."BenefitDisplayValue" IS NULL AND S."NewBenefitDisplayValue" IS NOT NULL)
        OR  (PB."BenefitDisplayValue" IS NOT NULL AND S."NewBenefitDisplayValue" != PB."BenefitDisplayValue")
        )
AND     S."HiosPlanID" IN ('36046MA0690999', '59763MA0030009', '42690MA1390006');


SELECT  PB."PlanBenefitID", PB."BenefitDisplayGroup", S."NewBenefitDisplayGroup"
FROM   "PlanBenefits" AS PB, "_NM_FixPBDisplayValue" AS S
WHERE   S."PlanBenefitID" = PB."PlanBenefitID"
AND     (
            (PB."BenefitDisplayGroup" IS NULL AND S."NewBenefitDisplayGroup" IS NOT NULL)
        OR  (PB."BenefitDisplayGroup" IS NOT NULL AND S."NewBenefitDisplayGroup" != PB."BenefitDisplayGroup")
        )
AND     S."HiosPlanID" IN ('36046MA0690999', '59763MA0030009', '42690MA1390006');
-- COMMIT;
