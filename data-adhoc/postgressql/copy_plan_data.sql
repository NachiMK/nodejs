
BEGIN;

--SELECT COUNT(*) as CountINStage FROM Stage_PlansAdded2019;
SELECT COUNT(*) AS CountBeforeInsert FROM "Plans" WHERE "Year" = 2019;

-- DROP TABLE IF EXISTS Stage_PlansAdded2019;
CREATE TABLE IF NOT EXISTS Stage_PlansAdded2019 AS 
SELECT  "HiosPlanID", "State", "Year", "PlanID", "CreatedDate"
FROM    "Plans"
WHERE   1 = 0 WITH NO DATA;

;WITH inserted_plans as
(
INSERT INTO "Plans"
    (
          "Year"
        , "HiosPlanID"
        , "PlanMarketingName"
        , "PlanDisplayName"
        , "State"
        , "Carrier"
        , "CarrierFriendlyName"
        , "PlanType"
        , "Metal"
        , "ServiceAreaID"
        , "IsActive"
        , "IsForSale"
        , "IsHSA"
        , "UseForModeling"
        , "BenefitsSummaryURL"
        , "IsApproved"
        , "PlanCollectionStatus"
        , "AggregateDeductible"
        , "AggregateOOP"
        , "GroupDisclaimer"
        , "HixmeCoinsurance"
        , "MedicareEligible"
        , "WetSignatureRequired"
        , "PreviousYearHiosPlanID"
        , "SBCType"
        , "FourTierRx"
        , "PlanID"
        , "GroupID"
        , "CreatedDate"
        , "UpdatedDate"
        , "PlanLastModified"
        , "HixmeValuePlus0"
        , "HixmeValuePlus500"
        , "HixmeValuePlus1000"
        , "HixmeValuePlus1500"
        , "HixmeValuePlus2000"
        , "HixmeValuePlus2500"
        , "ActuarialValue"
        , "OnlySellDuringOpenEnrollment"
        , "NextYearPlanStatus"
        , "CrosswalkHiosID"
        , "Exchange"
        , "MarketType"        
    )
SELECT
          2019 as "Year"
        , "HiosPlanID"
        , "PlanMarketingName"
        , "PlanDisplayName"
        , "State"
        , "Carrier"
        , "CarrierFriendlyName"
        , "PlanType"
        , "Metal"
        , "ServiceAreaID"
        , "IsActive"
        , "IsForSale"
        , "IsHSA"
        , "UseForModeling"
        , "BenefitsSummaryURL"
        , "IsApproved"
        , "PlanCollectionStatus"
        , "AggregateDeductible"
        , "AggregateOOP"
        , "GroupDisclaimer"
        , "HixmeCoinsurance"
        , "MedicareEligible"
        , "WetSignatureRequired"
        , "PreviousYearHiosPlanID"
        , "SBCType"
        , "FourTierRx"
        , uuid_generate_v4() AS "PlanID"
        , "GroupID"
        , CURRENT_TIMESTAMP as "CreatedDate"
        , CURRENT_TIMESTAMP as "UpdatedDate"
        , CURRENT_TIMESTAMP as "PlanLastModified"
        , "HixmeValuePlus0"
        , "HixmeValuePlus500"
        , "HixmeValuePlus1000"
        , "HixmeValuePlus1500"
        , "HixmeValuePlus2000"
        , "HixmeValuePlus2500"
        , "ActuarialValue"
        , "OnlySellDuringOpenEnrollment"
        , "NextYearPlanStatus"
        , "CrosswalkHiosID"
        , "Exchange"
        , "MarketType"
FROM    "Plans" P 
WHERE   "Year" = 2018
AND     NOT EXISTS (SELECT 1 FROM "Plans" AS Y2 WHERE Y2."HiosPlanID" = P."HiosPlanID" and Y2."Year" = 2019)
RETURNING   "HiosPlanID", "State", "Year", "PlanID", "CreatedDate"
)
INSERT INTO
    Stage_PlansAdded2019 
SELECT  *
FROM    inserted_plans
;

SELECT * FROM Stage_PlansAdded2019;
SELECT COUNT(*) AS CountAfterInsert FROM "Plans" WHERE "Year" = 2019;

-- COMMIT;
-- ROLLBACK; 

--------- Plan Rates Insert ---------------

SELECT COUNT(*) AS PlanRates_CountBeforeInsert FROM "PlanRates" WHERE "Year" = 2019;

-- DROP TABLE IF EXISTS Stage_PlanRatesAdded2019;
CREATE TABLE IF NOT EXISTS Stage_PlanRatesAdded2019 AS 
SELECT  "HiosPlanID", "Year", "PlanRateID", "CreatedDate"
FROM    "PlanRates"
WHERE   1 = 0 WITH NO DATA;

;WITH inserted_planrates as
(
INSERT INTO
    "PlanRates"
    (
         "Year"
        ,"HiosPlanID"
        ,"BaseRate"
        ,"AreaFactor01"
        ,"AreaFactor02"
        ,"AreaFactor03"
        ,"AreaFactor04"
        ,"AreaFactor05"
        ,"AreaFactor06"
        ,"AreaFactor07"
        ,"AreaFactor08"
        ,"AreaFactor09"
        ,"AreaFactor10"
        ,"AreaFactor11"
        ,"AreaFactor12"
        ,"AreaFactor13"
        ,"AreaFactor14"
        ,"AreaFactor15"
        ,"AreaFactor16"
        ,"AreaFactor17"
        ,"AreaFactor18"
        ,"AreaFactor19"
        ,"AreaFactor20"
        ,"AreaFactor21"
        ,"AreaFactor22"
        ,"AreaFactor23"
        ,"AreaFactor24"
        ,"AreaFactor25"
        ,"AreaFactor26"
        ,"AreaFactor27"
        ,"AreaFactor28"
        ,"AreaFactor29"
        ,"AreaFactor30"
        ,"AreaFactor31"
        ,"AreaFactor32"
        ,"AreaFactor33"
        ,"AreaFactor34"
        ,"AreaFactor35"
        ,"AreaFactor36"
        ,"AreaFactor37"
        ,"AreaFactor38"
        ,"AreaFactor39"
        ,"AreaFactor40"
        ,"AreaFactor41"
        ,"AreaFactor42"
        ,"AreaFactor43"
        ,"AreaFactor44"
        ,"AreaFactor45"
        ,"AreaFactor46"
        ,"AreaFactor47"
        ,"AreaFactor48"
        ,"AreaFactor49"
        ,"AreaFactor50"
        ,"AreaFactor51"
        ,"AreaFactor52"
        ,"AreaFactor53"
        ,"AreaFactor54"
        ,"AreaFactor55"
        ,"AreaFactor56"
        ,"AreaFactor57"
        ,"AreaFactor58"
        ,"AreaFactor59"
        ,"AreaFactor60"
        ,"AreaFactor61"
        ,"AreaFactor62"
        ,"AreaFactor63"
        ,"AreaFactor64"
        ,"AreaFactor65"
        ,"AreaFactor66"
        ,"AreaFactor67"
        ,"FourtyYearOldFactor"
        ,"CreatedDate"
        ,"UpdatedDate"
        ,"ProjectedRateIncrease"
        ,"IncreaseType"
        ,"RateStatus"
    )
SELECT  
        2019 as "Year"
        ,"HiosPlanID"
        ,"BaseRate"
        ,"AreaFactor01"
        ,"AreaFactor02"
        ,"AreaFactor03"
        ,"AreaFactor04"
        ,"AreaFactor05"
        ,"AreaFactor06"
        ,"AreaFactor07"
        ,"AreaFactor08"
        ,"AreaFactor09"
        ,"AreaFactor10"
        ,"AreaFactor11"
        ,"AreaFactor12"
        ,"AreaFactor13"
        ,"AreaFactor14"
        ,"AreaFactor15"
        ,"AreaFactor16"
        ,"AreaFactor17"
        ,"AreaFactor18"
        ,"AreaFactor19"
        ,"AreaFactor20"
        ,"AreaFactor21"
        ,"AreaFactor22"
        ,"AreaFactor23"
        ,"AreaFactor24"
        ,"AreaFactor25"
        ,"AreaFactor26"
        ,"AreaFactor27"
        ,"AreaFactor28"
        ,"AreaFactor29"
        ,"AreaFactor30"
        ,"AreaFactor31"
        ,"AreaFactor32"
        ,"AreaFactor33"
        ,"AreaFactor34"
        ,"AreaFactor35"
        ,"AreaFactor36"
        ,"AreaFactor37"
        ,"AreaFactor38"
        ,"AreaFactor39"
        ,"AreaFactor40"
        ,"AreaFactor41"
        ,"AreaFactor42"
        ,"AreaFactor43"
        ,"AreaFactor44"
        ,"AreaFactor45"
        ,"AreaFactor46"
        ,"AreaFactor47"
        ,"AreaFactor48"
        ,"AreaFactor49"
        ,"AreaFactor50"
        ,"AreaFactor51"
        ,"AreaFactor52"
        ,"AreaFactor53"
        ,"AreaFactor54"
        ,"AreaFactor55"
        ,"AreaFactor56"
        ,"AreaFactor57"
        ,"AreaFactor58"
        ,"AreaFactor59"
        ,"AreaFactor60"
        ,"AreaFactor61"
        ,"AreaFactor62"
        ,"AreaFactor63"
        ,"AreaFactor64"
        ,"AreaFactor65"
        ,"AreaFactor66"
        ,"AreaFactor67"
        ,"FourtyYearOldFactor"
        ,CURRENT_TIMESTAMP as "CreatedDate"
        ,CURRENT_TIMESTAMP as "UpdatedDate"
        ,null as "ProjectedRateIncrease"
        ,null as "IncreaseType"
        ,"RateStatus"
FROM    "PlanRates" AS PR
WHERE   "Year" = 2018
AND     NOT EXISTS (SELECT 1 FROM "PlanRates" AS Y2 WHERE Y2."HiosPlanID" = PR."HiosPlanID" and Y2."Year" = 2019)
AND     EXISTS (SELECT 1 FROM "Plans" AS P WHERE P."HiosPlanID" = PR."HiosPlanID" AND P."Year" = 2019)
RETURNING   "HiosPlanID", "Year", "PlanRateID", "CreatedDate"
)
INSERT INTO
    Stage_PlanRatesAdded2019
SELECT  * 
FROM    inserted_planrates;

SELECT * FROM Stage_PlanRatesAdded2019;
SELECT COUNT(*) AS PlanRates_CountAfterInsert FROM "PlanRates" WHERE "Year" = 2019;

--------- Plan Rates Insert ---------------

--------- Plan Benefits Insert ---------------

--SELECT COUNT(*) as CountINStage FROM Stage_PlanBenefitsAdded2019;
SELECT COUNT(*) AS PlanBenefits_CountBeforeInsert FROM "PlanBenefits" WHERE "Year" = 2019;

-- DROP TABLE IF EXISTS Stage_PlanBenefitsAdded2019;
CREATE TABLE IF NOT EXISTS Stage_PlanBenefitsAdded2019 AS 
SELECT  "HiosPlanID", "Year", "PlanBenefitID", "CreatedDate"
FROM    "PlanBenefits"
WHERE   1 = 0 WITH NO DATA;

;WITH inserted_planbenefits as
(
INSERT INTO "PlanBenefits"
    (
         "Year"
        ,"HiosPlanID"
        ,"Benefit"
        ,"ServiceNotCovered"
        ,"AppliesToDeductible"
        ,"AppliesToMOOP"
        ,"Coinsurance"
        ,"CopayAmount"
        ,"CopayDayLimit"
        ,"CoinsuranceCopayOrder"
        ,"MemberServicePaidCap"
        ,"CoverageVisitLimit"
        ,"SBCImage"
        ,"SBCValue"
        ,"SBCCleanValue"
        ,"BenefitDisplayValue"
        ,"BenefitDisplayGroup"
        ,"IncludeInDetailSBC"
        ,"IncludeInBundleCard"
        ,"Sort"
        ,"Notes"
        ,"Status"
        ,"FirstDollarVisits"
        ,"IsGrouped"
        ,"TieredBenefit"
        ,"SeparatedBenefit"
        ,"CopayAfterFirstVisits"
        ,"UpdateDate"
        ,"CopayDays"
        ,"CreatedDate"
        ,"UpdatedDate"
        ,"MaximumCoverage"
    )
SELECT
         2019 as "Year"
        ,"HiosPlanID"
        ,"Benefit"
        ,"ServiceNotCovered"
        ,"AppliesToDeductible"
        ,"AppliesToMOOP"
        ,"Coinsurance"
        ,"CopayAmount"
        ,"CopayDayLimit"
        ,"CoinsuranceCopayOrder"
        ,"MemberServicePaidCap"
        ,"CoverageVisitLimit"
        ,"SBCImage"
        ,"SBCValue"
        ,"SBCCleanValue"
        ,"BenefitDisplayValue"
        ,"BenefitDisplayGroup"
        ,"IncludeInDetailSBC"
        ,"IncludeInBundleCard"
        ,"Sort"
        ,null as "Notes"
        ,"Status"
        ,"FirstDollarVisits"
        ,"IsGrouped"
        ,"TieredBenefit"
        ,"SeparatedBenefit"
        ,"CopayAfterFirstVisits"
        ,CURRENT_TIMESTAMP AS "UpdateDate"
        ,"CopayDays"
        ,CURRENT_TIMESTAMP AS "CreatedDate"
        ,CURRENT_TIMESTAMP AS "UpdatedDate"
        ,"MaximumCoverage"
FROM    "PlanBenefits" PB 
WHERE   "Year" = 2018
AND     NOT EXISTS (SELECT 1 FROM "PlanBenefits" AS Y2 WHERE Y2."HiosPlanID" = PB."HiosPlanID" and Y2."Year" = 2019)
AND     EXISTS (SELECT 1 FROM "Plans" AS P2 WHERE P2."HiosPlanID" = PB."HiosPlanID" and P2."Year" = 2019)
RETURNING   "HiosPlanID", "Year", "PlanBenefitID", "CreatedDate"
)
INSERT INTO
    Stage_PlanBenefitsAdded2019 
SELECT  *
FROM    inserted_planbenefits
;

SELECT * FROM Stage_PlanBenefitsAdded2019;
SELECT COUNT(*) AS PlanBenefits_CountAfterInsert FROM "PlanBenefits" WHERE "Year" = 2019;
--------- Plan Benefits Insert ---------------

--------- Plan Service Areas Insert ---------------

--SELECT COUNT(*) as CountINStage FROM Stage_PlanServiceAreasAdded2019;
SELECT COUNT(*) AS PlanServiceAreas_CountBeforeInsert FROM "PlanServiceAreas" WHERE "Year" = 2019;

-- DROP TABLE IF EXISTS Stage_PlanServiceAreasAdded2019;
CREATE TABLE IF NOT EXISTS Stage_PlanServiceAreasAdded2019 AS 
SELECT  "HiosPlanID", "Year", "State", "PlanServiceAreaID", "CreatedDate"
FROM    "PlanServiceAreas"
WHERE   1 = 0 WITH NO DATA;

;WITH inserted_PlanServiceAreas as
(
INSERT INTO "PlanServiceAreas"
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
        ,"UpdatedDate"
    )
SELECT   "State"
        ,"IssuerID"
        ,'2018Copy' as "SourceName"
        ,"HiosPlanID"
        ,"ServiceAreaID"
        ,"ServiceAreaName"
        ,"CoverEntireState"
        ,"CountyCode"
        ,"PartialCounty"
        ,"Zipcode"
        ,2019 as "Year"
        ,"IsActive"
        ,CURRENT_TIMESTAMP AS "CreatedDate"
        ,CURRENT_TIMESTAMP AS "UpdatedDate"
FROM    "PlanServiceAreas" PSA 
WHERE   "Year" = 2018
AND     NOT EXISTS (SELECT 1 FROM "PlanServiceAreas" AS Y2 WHERE Y2."HiosPlanID" = PSA."HiosPlanID" and Y2."Year" = 2019 AND "State" = PSA."State")
AND     EXISTS (SELECT 1 FROM "Plans" AS P2 WHERE P2."HiosPlanID" LIKE PSA."HiosPlanID"||'%' and P2."Year" = 2019 AND P2."State" = PSA."State")
RETURNING   "HiosPlanID", "Year", "State", "PlanServiceAreaID", "CreatedDate"
)
INSERT INTO
    Stage_PlanServiceAreasAdded2019 
SELECT  *
FROM    inserted_PlanServiceAreas
;

SELECT * FROM Stage_PlanServiceAreasAdded2019;
SELECT COUNT(*) AS PlanServiceAreas_CountAfterInsert FROM "PlanServiceAreas" WHERE "Year" = 2019;
--------- Plan Service Areas Insert ---------------

