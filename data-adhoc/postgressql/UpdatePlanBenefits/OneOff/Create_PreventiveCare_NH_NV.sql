CREATE TABLE public."stage_2019_Missing_PreventiveCare_data643" AS 
SELECT * FROM "Plans" as p
WHERE   NOT EXISTS (SELECT 1 FROM "PlanBenefits" as Pb WHERE pb."HiosPlanID" = p."HiosPlanID" and pb."Year" = p."Year" AND "Benefit" = 'PreventiveCare')
AND EXISTS (SELECT 1 FROM "PlanBenefits" as Pb WHERE pb."HiosPlanID" = p."HiosPlanID" and pb."Year" = p."Year" AND "Benefit" != 'PreventiveCare')
--AND     "State" = 'CT' 
AND "Year" = 2019 AND "IsForSale" = true
;

-- SELECT * FROM "PlanBenefits" WHERE "Benefit" = 'PeventativeCare'

SELECT * FROM public."stage_2019_Missing_PreventiveCare_data643";

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
    CROSS JOIN public."stage_2019_Missing_PreventiveCare_data643" as T
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
