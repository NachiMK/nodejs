
BEGIN;
INSERT INTO
    "PlanServiceAreas"
    (
     "State"
    ,"IssuerID"
    ,"SourceName"
    ,"HiosPlanID"
    ,"ServiceAreaID"
    ,"ServiceAreaName"
    ,"CoverEntireState"
    ,"CountyCode"
    ,"PartialCounty"
    ,"Zipcode"
    ,"Year"
    ,"IsActive"
    ,"CreatedDate"    
    )
SELECT 
     "State"
    ,"IssuerID"
    ,"SourceName"
    ,"HiosPlanID"
    ,"ServiceAreaID"
    ,"ServiceAreaName"
    ,"CoverEntireState"
    ,'37' as "CountyCode"
    ,"PartialCounty"
    ,"Zipcode"
    ,"Year"
    ,"IsActive"
    ,CURRENT_TIMESTAMP AS "CreatedDate"
FROM  "PlanServiceAreas" 
WHERE "IssuerID" = '23552' and "State" = 'TN' AND "ServiceAreaID" = 'TNS001' AND "ServiceAreaName" = 'Oscar' AND "SourceName" = 'Carrier' 
AND   "HiosPlanID" = '23552TN003'
AND   "CoverEntireState" = false
AND   "PartialCounty" = false
AND   "Zipcode" is null
--AND   "CountyCode" = '37'
LIMIT 1;


SELECT  *
FROM  "PlanServiceAreas" 
WHERE "IssuerID" = '23552' and "State" = 'TN' AND "ServiceAreaID" = 'TNS001' AND "ServiceAreaName" = 'Oscar' AND "SourceName" = 'Carrier' 
AND   "HiosPlanID" = '23552TN003'
AND   "CoverEntireState" = false
AND   "PartialCounty" = false
AND   "Zipcode" is null
AND   "CountyCode" = '37';

COMMIT;