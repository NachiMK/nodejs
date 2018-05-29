CREATE TABLE public."stage_MO_Missing_PreventiveCare" AS 
SELECT * FROM "Plans" as p
WHERE   NOT EXISTS (SELECT 1 FROM "PlanBenefits" as Pb WHERE pb."HiosPlanID" = p."HiosPlanID" and pb."Year" = p."Year" AND "Benefit" = 'PreventiveCare')
AND p."HiosPlanID" IN (
'74483MO0040012'
,'74483MO0040015'
,'74483MO0040016'
,'74483MO0040018'
,'74483MO0040022'
,'99273MO0090005'
,'99723MO0090001'
,'99723MO0090002'
,'99723MO0090003'
,'99723MO0090004')
AND "Carrier" IN (
'Cigna Healthcare'
,'Ambetter From Home State Health'
)
;

-- SELECT * FROM "PlanBenefits" WHERE "Benefit" = 'PeventativeCare'

SELECT * FROM public."stage_MO_Missing_PreventiveCare"

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
    CROSS JOIN public."stage_MO_Missing_PreventiveCare" as T
    WHERE   NOT EXISTS (SELECT  1
                        FROM    public."PlanBenefits" as pb 
                        WHERE   stg."Year"          = pb."Year"
                        AND     stg."HiosPlanID"    IN (
                                                        '74483MO0040012'
                                                        ,'74483MO0040015'
                                                        ,'74483MO0040016'
                                                        ,'74483MO0040018'
                                                        ,'74483MO0040022'
                                                        ,'99273MO0090005'
                                                        ,'99723MO0090001'
                                                        ,'99723MO0090002'
                                                        ,'99723MO0090003'
                                                        ,'99723MO0090004')
                        AND     stg."Benefit"       = pb."Benefit")
    AND     stg."Benefit" = 'PreventiveCare'
    AND     stg."PlanBenefitID" = '332007'
    AND     stg."Year" = 2018
    ;
COMMIT;