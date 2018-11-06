SELECT * FROM "Plans" WHERE "Year" = 2019 AND "HiosPlanID" = '70285CA7740001'

SELECT * FROM "PlanServiceAreas" WHERE "HiosPlanID" = '48396ME079' and "IssuerID" = '48396' AND "CountyCode" = '7'

SELECT "Year", "HiosPlanID" FROM "Plans" WHERE "Year" = 2019 group by "Year", "HiosPlanID" having count(*) > 1;
SELECT "PlanID" FROM "Plans" WHERE "Year" = 2019 group by "PlanID" having count(*) > 1;
SELECT "Year", "HiosPlanID", "Benefit" FROM "PlanBenefits" WHERE "Year"=2019 group by "Year", "HiosPlanID", "Benefit" having count(*) > 1;
SELECT "Year", "HiosPlanID" FROM "PlanRates" WHERE "Year" = 2019 group by "Year", "HiosPlanID" having count(*) > 1;
SELECT "Year", "HiosPlanID" FROM "PlanNetworks" WHERE "Year" = 2019 group by "Year", "HiosPlanID" having count(*) > 1;
SELECT "Year", "HiosPlanID" FROM "PlanNetworks" WHERE "Year" = 2019 group by "Year", "HiosPlanID" having count(*) > 1;

CREATE TABLE public."DuplicateServiceAreaID" AS 
SELECT "Year", "HiosPlanID", "State", "IssuerID", "ServiceAreaID", "CoverEntireState", "CountyCode", "PartialCounty", "Zipcode", Count(*), MIN("PlanServiceAreaID") as FirstSvcID, MAX("PlanServiceAreaID") as LastSvcID
FROM "PlanServiceAreas" WHERE "Year" = 2019 
group by "Year", "HiosPlanID", "State", "IssuerID", "ServiceAreaID", "CoverEntireState", "CountyCode", "PartialCounty", "Zipcode" having count(*) > 1;

SELECT  FirstSVCID, LastSvcID, PSA.*
FROM    "PlanServiceAreas" AS PSA
INNER
JOIN    "DuplicateServiceAreaID" AS D ON PSA."Year" = D."Year"
            AND PSA."HiosPlanID" = D."HiosPlanID"
            AND PSA."State" = D."State"
            AND PSA."IssuerID" = D."IssuerID"
            AND PSA."ServiceAreaID" = D."ServiceAreaID"
            AND PSA."CoverEntireState" = D."CoverEntireState"
            AND PSA."CountyCode" = D."CountyCode"
            AND PSA."PartialCounty" = D."PartialCounty"
            AND COALESCE(PSA."Zipcode", '') = COALESCE(D."Zipcode", '')
WHERE   PSA."Year" = 2019
ORDER BY PSA."HiosPlanID"
        ,PSA."State"
        ,PSA."IssuerID"
        ,PSA."ServiceAreaID"
        ,PSA."CoverEntireState"
        ,PSA."CountyCode"
        ,PSA."PartialCounty"
;


-- DELETE the Duplicate one.
BEGIN;
DELETE
FROM    "PlanServiceAreas" AS PSA
WHERE EXISTS (SELECT 1 FROM "DuplicateServiceAreaID" AS D WHERE PSA."Year" = D."Year"
            AND PSA."HiosPlanID" = D."HiosPlanID"
            AND PSA."State" = D."State"
            AND PSA."IssuerID" = D."IssuerID"
            AND PSA."ServiceAreaID" = D."ServiceAreaID"
            AND PSA."CoverEntireState" = D."CoverEntireState"
            AND PSA."CountyCode" = D."CountyCode"
            AND PSA."PartialCounty" = D."PartialCounty"
            AND COALESCE(PSA."Zipcode", '') = COALESCE(D."Zipcode", '')
            AND PSA."PlanServiceAreaID" = D.FirstSVCID);
COMMIT;


SELECT  P.*
FROM    "Plans" P
LEFT
JOIN    "PlanServiceAreas" AS PSA ON PSA."Year" = P."Year" AND PSA."HiosPlanID" = P."HiosPlanID"
                                                            AND PSA."Zipcode" = '90063'
                                                            AND PSA."CountyCode" = 16
                                                            AND PSA."State" = P."State"                                    
LEFT
JOIN    "PlanRates" AS PR ON PR."Year" = P."Year" AND PR."HiosPlanID" = P."HiosPlanID"
                                                  AND PR."AreaFactor16" is not null
WHERE   P."Year" = 2019
AND     P."IsForSale" = true
AND     P."State" = 'CA'

SELECT  P."Year", P."HiosPlanID"
FROM    "Plans" P
LEFT
JOIN    "PlanServiceAreas" AS PSA ON PSA."Year" = P."Year" AND PSA."HiosPlanID" = P."HiosPlanID"
                                                            AND PSA."Zipcode" = '90063'
                                                            AND PSA."CountyCode" = 16
                                                            AND PSA."State" = P."State"                                    
LEFT
JOIN    "PlanRates" AS PR ON PR."Year" = P."Year" AND PR."HiosPlanID" = P."HiosPlanID"
                                                  AND PR."AreaFactor16" is not null
WHERE   P."Year" = 2019
AND     P."IsForSale" = true
AND     P."State" = 'CA'
GROUP BY
    P."Year", P."HiosPlanID"
HAVING COUNT(*) > 1


SELECT "Year" , "HiosPlanID"
FROM "PlanRates" PR WHERE "Year" = 2019 AND "AreaFactor16" is not null
AND EXISTS (SELECT 1 FROM "Plans" P WHERE P."Year" = 2019 AND P."HiosPlanID" = PR."HiosPlanID" AND P."State" = 'CA')
group by "Year" , "HiosPlanID" having count(*) > 1

SELECT "Year" , "HiosPlanID"
FROM "Plans" P WHERE "Year" = 2019 AND P."State" = 'CA'
AND "ServiceAreaID" is not null
AND "IsForSale" = true
AND EXISTS (SELECT 1 FROM "PlanRates" PR WHERE PR."Year" = 2019 AND "AreaFactor16" is not null AND P."HiosPlanID" = PR."HiosPlanID")
AND EXISTS (SELECT * FROM "PlanServiceAreas" WHERE P."HiosPlanID" ~ "HiosPlanID" AND "Year" = 2019 AND (P."ServiceAreaID" IS NULL OR (P."ServiceAreaID" IS NOT NULL AND P."ServiceAreaID" = "ServiceAreaID") ) )
group by "Year" , "HiosPlanID" having count(*) > 1;

SELECT *
FROM "Plans" P WHERE "Year" = 2019 AND P."State" = 'CA'
AND "ServiceAreaID" is not null
AND "IsForSale" = true
AND EXISTS (SELECT 1 FROM "PlanRates" PR WHERE PR."Year" = 2019 AND "AreaFactor16" is not null AND P."HiosPlanID" = PR."HiosPlanID")
AND EXISTS (SELECT * FROM "PlanServiceAreas" WHERE P."HiosPlanID" ~ "HiosPlanID" AND "Year" = 2019 AND (P."ServiceAreaID" IS NULL OR (P."ServiceAreaID" IS NOT NULL AND P."ServiceAreaID" = "ServiceAreaID") ) )
AND "HiosPlanID" IN ('10544CA0120001', '70285CA8050016')

SELECT * FROM "Plans" WHERE "HiosPlanID" = '70285CA8050016' AND "Year" = 2019;
SELECT * FROM "Plans" WHERE "Year" = 2019 AND "IsForSale" AND "ServiceAreaID" is not null AND "State" = 'CA';
SELECT * FROM "PlanServiceAreas" WHERE "HiosPlanID" = '70285CA8050016' AND "Year" = 2019;
SELECT * FROM "PlanRates" WHERE "HiosPlanID" = '70285CA7740001' AND "Year" = 2019;

SELECT * FROM "DuplicateServiceAreaID" WHERE "HiosPlanID" in ('70285CA7740001', '70285CA1310001', '70285CA1250001')

-- Plans with ServiceAreaID but missing rows in PlanServiceAreas Table, This needs to be fixed by Lori/Evan
SELECT *
FROM "Plans" P WHERE "Year" = 2019 AND P."State" = 'CA'
AND "ServiceAreaID" is not null
AND "IsForSale" = true
AND NOT EXISTS (SELECT * FROM "PlanServiceAreas" WHERE "HiosPlanID" = LEFT(P."HiosPlanID", 10) AND "Year" = 2019)

SELECT * FROM "PlanServiceAreas" WHERE "HiosPlanID" ~ '70285CA805' AND "Year" = 2019 AND "ServiceAreaID" = 'CAS026' AND "CountyCode" = '37' AND "Zipcode" = '90063';

SELECT * FROM "Plans" WHERE "Year" = 2019 AND "IsForSale" = true AND "State" = 'CA' and "HiosPlanID" = '70285CA7740001';
SELECT * FROM "Plans" WHERE "Year" = 2019 AND "IsForSale" AND "ServiceAreaID" is not null AND "State" = 'CA' and "HiosPlanID" = '10544CA0120001';


SELECT "PlanServiceAreas"."PlanServiceAreaID", "PlanServiceAreas"."State", "PlanServiceAreas"."HiosPlanID"
, "PlanServiceAreas"."ServiceAreaID", "PlanServiceAreas"."CoverEntireState", "PlanServiceAreas"."CountyCode"
, "PlanServiceAreas"."PartialCounty", "PlanServiceAreas"."Zipcode", "PlanServiceAreas"."Year"
, "PlanServiceAreas"."IsActive" 
FROM "PlanServiceAreas" 
JOIN (VALUES (2019, '70285CA805' ,'CAS026')) AS x (Year, HiosPlanID, ServiceAreaID) ON x.Year::integer = "PlanServiceAreas"."Year" 
AND x.HiosPlanID = "PlanServiceAreas"."HiosPlanID"
AND x.ServiceAreaID = "PlanServiceAreas"."ServiceAreaID" 
WHERE "PlanServiceAreas"."IsActive" = true


-- Find all Plans in 37/90063 or Plans in all areas
SELECT P."HiosPlanID"
FROM "Plans" P WHERE "Year" = 2019 AND P."State" = 'CA'
AND "ServiceAreaID" is null
AND "IsForSale" = true
AND EXISTS (SELECT 1 FROM "PlanRates" PR WHERE PR."Year" = 2019 AND "AreaFactor16" is not null AND P."HiosPlanID" = PR."HiosPlanID")

UNION

SELECT P."HiosPlanID"
FROM "Plans" P WHERE "Year" = 2019 AND P."State" = 'CA'
AND "ServiceAreaID" is not null
AND "IsForSale" = true
AND EXISTS (SELECT 1 FROM "PlanRates" PR WHERE PR."Year" = 2019 AND "AreaFactor16" is not null AND P."HiosPlanID" = PR."HiosPlanID")
AND EXISTS (SELECT * FROM "PlanServiceAreas" WHERE "HiosPlanID" = LEFT(P."HiosPlanID", 10) AND "Year" = 2019 AND "CoverEntireState" = true)

UNION

SELECT P."HiosPlanID"
FROM "Plans" P WHERE "Year" = 2019 AND P."State" = 'CA'
AND "ServiceAreaID" is not null
AND "IsForSale" = true
AND EXISTS (SELECT 1 FROM "PlanRates" PR WHERE PR."Year" = 2019 AND "AreaFactor16" is not null AND P."HiosPlanID" = PR."HiosPlanID")
AND EXISTS (SELECT * FROM "PlanServiceAreas" WHERE "HiosPlanID" = LEFT(P."HiosPlanID", 10) AND "Year" = 2019 AND "CoverEntireState" = false and "CountyCode" = '37' AND "PartialCounty" = false)

UNION

SELECT P."HiosPlanID"
FROM "Plans" P WHERE "Year" = 2019 AND P."State" = 'CA'
AND "ServiceAreaID" is not null
AND "IsForSale" = true
AND EXISTS (SELECT 1 FROM "PlanRates" PR WHERE PR."Year" = 2019 AND "AreaFactor16" is not null AND P."HiosPlanID" = PR."HiosPlanID")
AND EXISTS (SELECT * FROM "PlanServiceAreas" WHERE "HiosPlanID" = LEFT(P."HiosPlanID", 10) AND "Year" = 2019 
AND "CoverEntireState" = false and "CountyCode" = '37' AND "PartialCounty" = true
AND "Zipcode" = '90063')
