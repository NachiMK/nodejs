--DROP VIEW IF EXISTS public.vw_AxeneErrorReport
CREATE VIEW public.vw_AxeneErrorReport 
AS
SELECT  FP."Year"
        ,FP."HiosPlanID"
        ,FP."PlanMarketingName"
        ,FP."State"
        ,FP."Carrier"
        ,FP."PlanType"
        ,FP."Metal"
        ,FP."IsHSA"
        ,FP."IsActive"
        ,FP."IsForSale"
        ,FP."IsApproved"
        ,FP."UseForModeling"
        ,FP."PlanID"
        ,FP."GroupID"
        ,AF."FileName"
        ,AF."Status"
        ,AE."CategoryName"
        ,AE."CategoryDescription"
        ,AE."RuleName"
        ,AE."RuleDescription"
        --,"PlanBenefitType"
        ,AF."AxeneBatchID"
        ,ABE."AxeneBatchFileID"
    FROM    "AxenePlanBenefitErrors" ABE
    INNER
    JOIN    "AxeneBatchFiles" AF ON AF."ID" = ABE."AxeneBatchFileID" 
    LEFT
    JOIN    "AxeneErrors" AS AE ON AE."ID"  = ABE."AxeneErrorID"
    LEFT
    JOIN    LATERAL
            (
                    SELECT   p."Year"
                            ,p."HiosPlanID"
                            ,p."PlanMarketingName"
                            ,p."State"
                            ,p."Carrier"
                            ,p."PlanType"
                            ,p."Metal"
                            ,CASE WHEN LOWER(LEFT(p."Metal", 1)) = 'c' THEN 'b' ELSE LOWER(LEFT(p."Metal", 1)) END as "MetalFirstChar"
                            ,CAST(p."IsHSA" as VARCHAR(5)) AS "IsHSA"
                            ,CAST(p."IsActive" as VARCHAR(5)) AS "IsActive"
                            ,CAST(p."IsForSale" as VARCHAR(5)) AS "IsForSale"
                            ,CAST(p."IsApproved" as VARCHAR(5)) AS "IsApproved"
                            ,CAST(p."UseForModeling" as VARCHAR(5)) AS "UseForModeling"
                            ,p."GroupID"
                            ,p."PlanID"
                    FROM    "Plans" AS P
                    WHERE   LEFT(REPLACE(AF."FileName", AF."AxeneBatchID" || '_', ''), 36) LIKE CAST(P."PlanID" AS VARCHAR)
                    --AND     p."Year" = 2018
            ) AS FP ON true
WHERE   "Status" = 'error'
ORDER BY
        AF."AxeneBatchID", "PlanID", "FileName", "CategoryName", "RuleName"
;

/*
    SELECT * FROM vw_AxeneErrorReport WHERE "Year" = 2018 AND "AxeneBatchID" = '28'
*/