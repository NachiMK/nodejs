CREATE TABLE public."stage_2019_Missing_PreventiveCare_data618" AS 
SELECT * FROM "Plans" as p
WHERE   NOT EXISTS (SELECT 1 FROM "PlanBenefits" as Pb WHERE pb."HiosPlanID" = p."HiosPlanID" and pb."Year" = p."Year" AND "Benefit" = 'PreventiveCare')
--AND     "State" = 'CT' 
AND "Year" = 2019 AND "IsForSale" = true
;

-- SELECT * FROM "PlanBenefits" WHERE "Benefit" = 'PeventativeCare'

SELECT * FROM public."stage_2019_Missing_PreventiveCare_data618"

BEGIN;
INSERT INTO
            "PlanBenefits"
            (
                "Year"
                ,"HiosPlanID"
                ,"Benefit"
                ,"ServiceNotCovered"
                ,"AppliesToDeductible"
                ,"Coinsurance"
                ,"CopayAmount"
                ,"CopayDayLimit"
                ,"CoinsuranceCopayOrder"
                ,"MemberServicePaidCap"
                ,"CoverageVisitLimit"
                ,"Notes"
                ,"Status"
                ,"FirstDollarVisits"
                ,"IsGrouped"
                ,"CopayAfterFirstVisits"
                ,"CreatedDate"
                ,"UpdatedDate"
            )
    SELECT       T."Year" as "Year"
                ,T."HiosPlanID"
                ,stg."Benefit"
                ,stg."ServiceNotCovered"
                ,stg."AppliesToDeductible"
                ,stg."Coinsurance"
                ,stg."CopayAmount"
                ,stg."CopayDayLimit"
                ,stg."CoinsuranceCopayOrder"
                ,stg."MemberServicePaidCap"
                ,stg."CoverageVisitLimit"
                ,stg."Notes"
                ,stg."Status"
                ,stg."FirstDollarVisits"
                ,stg."IsGrouped"
                ,stg."CopayAfterFirstVisits"
                ,CURRENT_TIMESTAMP as "CreatedDate"
                ,CURRENT_TIMESTAMP as "UpdatedDate"
    FROM    public."PlanBenefits" as stg
    CROSS JOIN public."stage_2019_Missing_PreventiveCare_data618" as T
    WHERE   NOT EXISTS (SELECT  1
                        FROM    public."PlanBenefits" as pb 
                        WHERE   T."Year"            = pb."Year"
                        AND     T."HiosPlanID"      = pb."HiosPlanID"
                        AND     'PreventiveCare'    = pb."Benefit")
    AND     stg."Benefit" = 'PreventiveCare'
    AND     stg."PlanBenefitID" = '464493'
    ;

-- Commit if # of rows updated is 10
COMMIT;


CREATE TEMPORARY TABLE _NM_DelPB AS 
SELECT "Year", "HiosPlanID" FROM public."stage_2019_Missing_PreventiveCare_data618" T
WHERE 1 = (SELECT COUNT(*) FROM "PlanBenefits" WHERE T."HiosPlanID" = "HiosPlanID" and "Year" = T."Year")

BEGIN;
DELETE FROM "PlanBenefits" as pb1
WHERE NOT EXISTS (SELECT 1 FROM "PlanBenefits" as pb2 WHERE pb2."Year" =  pb1."Year" and pb2."HiosPlanID" = pb1."HiosPlanID"
AND pb2."Benefit" != 'PreventiveCare')
AND EXISTS (SELECT 1 FROM _NM_DelPB WHERE "HiosPlanID" = pb1."HiosPlanID" and "Year" = pb1."Year")
COMMIT;