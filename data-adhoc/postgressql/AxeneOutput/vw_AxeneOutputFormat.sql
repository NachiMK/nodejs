-- DROP VIEW IF EXISTS public.vw_AxeneOutputFormat;
CREATE VIEW public.vw_AxeneOutputFormat 
AS    
SELECT 
        CAST('TRUE' as VARCHAR(5)) as "isOriginal"
        ,CAST('' as VARCHAR(255)) as "fileName"
        ,p."Year"
        ,p."HiosPlanID"
        ,p."PlanMarketingName"
        ,p."State"
        ,p."Carrier"
        ,p."PlanType"
        ,p."Metal"
        ,CAST(p."IsHSA" as VARCHAR(5)) AS "IsHSA"
        ,CAST(p."IsActive" as VARCHAR(5)) AS "IsActive"
        ,CAST(p."IsForSale" as VARCHAR(5)) AS "IsForSale"
        ,CAST(p."IsApproved" as VARCHAR(5)) AS "IsApproved"
        ,CAST(p."UseForModeling" as VARCHAR(5)) AS "UseForModeling"
        ,p."PlanID" AS "PlanID"
        ,p."GroupID"
        ,p."ActuarialValue"	
        ,p."HixmeValuePlus0"
        ,p."HixmeValuePlus500"
        ,p."HixmeValuePlus1000"
        ,p."HixmeValuePlus1500"
        ,p."HixmeValuePlus2000"
        ,p."HixmeValuePlus2500"
FROM    "Plans" as p
WHERE   1 = 0;