-- Plan Service Areas Report
SELECT 
         "PlanServiceAreaID"
        ,"Year"
        ,"State"
        ,"IssuerID"
        ,"SourceName"
        ,"HiosPlanID"
        ,"ServiceAreaID"
        ,"ServiceAreaName"
        ,"CoverEntireState"
        ,"CountyCode"
        ,"PartialCounty"
        ,"Zipcode"
        ,"IsActive"
FROM   public."PlanServiceAreas"
WHERE  1 = 1
AND    "Year" = 2018
--AND    "State" = 'CA'
--AND    "IsActive" = true
ORDER BY
        "Year"
       ,"State"
       ,"IssuerID"
       ,"HiosPlanID"
       ,"ServiceAreaID"
       ,"CountyCode"
       ,"Zipcode";


-- Plan Service Areas Report
SELECT 
         "PlanServiceAreaID"
        ,"Year"
        ,"State"
        ,"IssuerID"
        ,"SourceName"
        ,"HiosPlanID"
        ,"ServiceAreaID"
        ,"ServiceAreaName"
        ,"CoverEntireState"
        ,"CountyCode"
        ,"PartialCounty"
        ,"Zipcode"
        ,"IsActive"
FROM   public."PlanServiceAreas" as psa
WHERE  1 = 1
AND    EXISTS (SELECT 1 FROM vw_stage_planserviceareas as v WHERE v."PlanServiceAreaID" = psa."PlanServiceAreaID")
ORDER BY
        "Year"
       ,"State"
       ,"IssuerID"
       ,"HiosPlanID"
       ,"ServiceAreaID"
       ,"CountyCode"
       ,"Zipcode";

-- Plan Service Areas Report
SELECT 
         "PlanServiceAreaID"
        ,"Year"
        ,"State"
        ,"IssuerID"
        ,"SourceName"
        ,"HiosPlanID"
        ,"ServiceAreaID"
        ,"ServiceAreaName"
        ,"CoverEntireState"
        ,"CountyCode"
        ,"PartialCounty"
        ,"Zipcode"
        ,"IsActive"
        ,"UpdatedDate"
FROM   public."PlanServiceAreas" as pb       
WHERE  EXISTS (SELECT  1
                FROM    vw_stage_planserviceareas as stg 
                WHERE   stg."Year"          = pb."Year"
                AND     stg."HiosPlanID"    = pb."HiosPlanID"
                AND     pb."IssuerID"       = stg."IssuerID"
                AND     pb."ServiceAreaID"  = stg."ServiceAreaID"
                AND     pb."State"          = stg."State"
                AND     COALESCE(pb."CountyCode", '0')   = COALESCE(stg."CountyCode", '0')
                AND     COALESCE(pb."Zipcode", '0') = COALESCE(stg."Zipcode", '0')
                )
--AND "IssuerID" = '14002'
;

SELECT * FROM "PlanServiceAreas" WHERE "IssuerID" = '33755';
SELECT * FROM vw_stage_planserviceareas;