
CREATE TABLE public."stage_Plans_Missing_PreventiveCare" AS 
SELECT * FROM "Plans" as p
WHERE   NOT EXISTS (SELECT 1 FROM "PlanBenefits" as Pb WHERE pb."HiosPlanID" = p."HiosPlanID" and pb."Year" = p."Year" AND "Benefit" = 'PreventiveCare')
AND     "Year" = 2018 AND "IsForSale" = true
;

-- SELECT * FROM "PlanBenefits" WHERE "Benefit" = 'PeventativeCare'

SELECT * FROM public."stage_Plans_Missing_PreventiveCare"

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
    SELECT       T."Year"
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
    CROSS JOIN public."stage_Plans_Missing_PreventiveCare" as T
    WHERE   NOT EXISTS (SELECT  1
                        FROM    public."PlanBenefits" as pb 
                        WHERE   stg."Year"          = T."Year"
                        AND     stg."HiosPlanID"    = T."HiosPlanID"
                        AND     stg."Benefit"       = pb."Benefit")
    AND     stg."Benefit" = 'PreventiveCare'
    AND     stg."PlanBenefitID" = '464493'
    AND     stg."Year" = 2018
    ;

-- Commit if # of rows updated is 16
COMMIT;