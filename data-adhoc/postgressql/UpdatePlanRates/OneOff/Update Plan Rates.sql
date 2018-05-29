-- SELECT * FROM public.stage_planrates_040620182 LIMIT 100;
-- SELECT * FROM public."Plans" LIMIT 100;
-- SELECT * FROM public."PlanRates" LIMIT 100;
-- SELECT * FROM public."Plans" WHERE "State" = 'MO' AND "Year" = 2018 LIMIT 100;
-- SELECT * FROM "PlanRates" WHERE "HiosPlanID" IN ('32753MO0950004') AND "Year" = 2018 LIMIT 200;

/**********************************************************/
/**********************************************************/
-- Make sure you first export data into a state table, to do that use
-- Update_PlanRates.sh and Update Plan Rates - Create table.sql
-- ALSO make sure you replace 040620182 with new date.
/**********************************************************/
/**********************************************************/

SELECT COUNT(*) as CopiedRowCount FROM public.stage_planrates_rp502_oh_20180509;

-- Sanity Checks
SELECT Count(*) as "RowsWithNoIDs" -- Delete these rows
FROM   public.stage_planrates_rp502_oh_20180509
WHERE  "HIOS Plan ID" IS NULL;

-- Delete Plans with no HIOS IDs
BEGIN;

DELETE 
FROM   public.stage_planrates_rp502_oh_20180509
WHERE  "HIOS Plan ID" IS NULL;

COMMIT;

-- More Sanity Checks
SELECT   Count(*) as "InvalidRows" -- if more than zero stop updates
FROM     public.stage_planrates_rp502_oh_20180509
WHERE    "plan_year" is null
OR       "State" is null
OR       "HIOS Plan ID" is null;

-- Do we have all the plans?
SELECT   COUNT(*) as "MissingPlanCount" -- If more than zero stop updates
FROM     public.stage_planrates_rp502_oh_20180509 as s
WHERE    NOT EXISTS (SELECT 1 FROM "Plans" as p WHERE s."plan_year" = p."Year" and s."HIOS Plan ID" = p."HiosPlanID" AND s."State" = p."State")
;

-- Any plans that doesnt have rates already
SELECT   COUNT(*) as "MissingPlanRatesCount" -- If more than zero stop updates
FROM     public.stage_planrates_rp502_oh_20180509 as s
WHERE    NOT EXISTS (SELECT 1 FROM "PlanRates" as pr WHERE s."plan_year" = pr."Year" and s."HIOS Plan ID" = pr."HiosPlanID")
;

-- do we have any rows to update? if not dont proceed
-- Plans
SELECT   COUNT(*) as "Plans_RowsToUpdate" -- If zero then no need to update Plans
FROM     public.stage_planrates_rp502_oh_20180509 as s
INNER 
JOIN     public."Plans" as p ON  s."plan_year" = p."Year" 
                             AND s."HIOS Plan ID" = p."HiosPlanID"
                             AND s."State" = p."State"
WHERE    1 = 0
OR ((s."Carrier" is not null and p."Carrier" is null) OR (s."Carrier" is null and p."Carrier" is not null) OR (s."Carrier" != p."Carrier"))
OR ((s."Carrier Marketing Name" is not null and p."CarrierFriendlyName" is null) OR (s."Carrier Marketing Name" is null and p."CarrierFriendlyName" is not null) OR (s."Carrier Marketing Name" != p."CarrierFriendlyName"))
OR ((s."plan_name" is not null and p."PlanDisplayName" is null) OR (s."plan_name" is null and p."PlanDisplayName" is not null) OR (s."plan_name" != p."PlanDisplayName"))
OR ((s."plan_type" is not null and p."PlanType" is null) OR (s."plan_type" is null and p."PlanType" is not null) OR (s."plan_type" != p."PlanType"))
OR ((s."level" is not null and p."Metal" is null) OR (s."level" is null and p."Metal" is not null) OR (s."level" != p."Metal"))
OR ((s."HSA" is not null and p."IsHSA" is null) OR (s."HSA" is null and p."IsHSA" is not null) OR (s."HSA" != p."IsHSA"))
OR ((s."is_active" is not null and p."IsActive" is null) OR (s."is_active" is null and p."IsActive" is not null) OR (s."is_active" != p."IsActive"))
OR ((s."is_for_sale" is not null and p."IsForSale" is null) OR (s."is_for_sale" is null and p."IsForSale" is not null) OR (s."is_for_sale" != p."IsForSale"))
OR ((s."service_area_id" is not null and p."ServiceAreaID" is null) OR (s."service_area_id" is null and p."ServiceAreaID" is not null) OR (s."service_area_id" != p."ServiceAreaID"))
;

-- Plan Rates
SELECT   COUNT(*) as "PlanRates_RowsToUpdate" -- If zero then no need to update Plans
FROM     public.stage_planrates_rp502_oh_20180509 as s
INNER 
JOIN     public."Plans" as p ON  s."plan_year" = p."Year" 
                             AND s."HIOS Plan ID" = p."HiosPlanID"
                             AND s."State" = p."State"
INNER 
JOIN     public."PlanRates" as pr ON p."Year" = pr."Year" and p."HiosPlanID" = pr."HiosPlanID"
WHERE    1 = 0
OR ((s."BaseRate" is not null and pr."BaseRate" is null) OR (s."BaseRate" is null and pr."BaseRate" is not null) OR (s."BaseRate" != pr."BaseRate"))
OR ((s."RA01" is not null and pr."AreaFactor01" is null) OR (s."RA01" is null and pr."AreaFactor01" is not null) OR (s."RA01" != pr."AreaFactor01"))
OR ((s."RA02" is not null and pr."AreaFactor02" is null) OR (s."RA02" is null and pr."AreaFactor02" is not null) OR (s."RA02" != pr."AreaFactor02"))
OR ((s."RA03" is not null and pr."AreaFactor03" is null) OR (s."RA03" is null and pr."AreaFactor03" is not null) OR (s."RA03" != pr."AreaFactor03"))
OR ((s."RA04" is not null and pr."AreaFactor04" is null) OR (s."RA04" is null and pr."AreaFactor04" is not null) OR (s."RA04" != pr."AreaFactor04"))
OR ((s."RA05" is not null and pr."AreaFactor05" is null) OR (s."RA05" is null and pr."AreaFactor05" is not null) OR (s."RA05" != pr."AreaFactor05"))
OR ((s."RA06" is not null and pr."AreaFactor06" is null) OR (s."RA06" is null and pr."AreaFactor06" is not null) OR (s."RA06" != pr."AreaFactor06"))
OR ((s."RA07" is not null and pr."AreaFactor07" is null) OR (s."RA07" is null and pr."AreaFactor07" is not null) OR (s."RA07" != pr."AreaFactor07"))
OR ((s."RA08" is not null and pr."AreaFactor08" is null) OR (s."RA08" is null and pr."AreaFactor08" is not null) OR (s."RA08" != pr."AreaFactor08"))
OR ((s."RA09" is not null and pr."AreaFactor09" is null) OR (s."RA09" is null and pr."AreaFactor09" is not null) OR (s."RA09" != pr."AreaFactor09"))
OR ((s."RA10" is not null and pr."AreaFactor10" is null) OR (s."RA10" is null and pr."AreaFactor10" is not null) OR (s."RA10" != pr."AreaFactor10"))
OR ((s."RA11" is not null and pr."AreaFactor11" is null) OR (s."RA11" is null and pr."AreaFactor11" is not null) OR (s."RA11" != pr."AreaFactor11"))
OR ((s."RA12" is not null and pr."AreaFactor12" is null) OR (s."RA12" is null and pr."AreaFactor12" is not null) OR (s."RA12" != pr."AreaFactor12"))
OR ((s."RA13" is not null and pr."AreaFactor13" is null) OR (s."RA13" is null and pr."AreaFactor13" is not null) OR (s."RA13" != pr."AreaFactor13"))
OR ((s."RA14" is not null and pr."AreaFactor14" is null) OR (s."RA14" is null and pr."AreaFactor14" is not null) OR (s."RA14" != pr."AreaFactor14"))
OR ((s."RA15" is not null and pr."AreaFactor15" is null) OR (s."RA15" is null and pr."AreaFactor15" is not null) OR (s."RA15" != pr."AreaFactor15"))
OR ((s."RA16" is not null and pr."AreaFactor16" is null) OR (s."RA16" is null and pr."AreaFactor16" is not null) OR (s."RA16" != pr."AreaFactor16"))
OR ((s."RA17" is not null and pr."AreaFactor17" is null) OR (s."RA17" is null and pr."AreaFactor17" is not null) OR (s."RA17" != pr."AreaFactor17"))
OR ((s."RA18" is not null and pr."AreaFactor18" is null) OR (s."RA18" is null and pr."AreaFactor18" is not null) OR (s."RA18" != pr."AreaFactor18"))
OR ((s."RA19" is not null and pr."AreaFactor19" is null) OR (s."RA19" is null and pr."AreaFactor19" is not null) OR (s."RA19" != pr."AreaFactor19"))
OR ((s."RA20" is not null and pr."AreaFactor20" is null) OR (s."RA20" is null and pr."AreaFactor20" is not null) OR (s."RA20" != pr."AreaFactor20"))
OR ((s."RA21" is not null and pr."AreaFactor21" is null) OR (s."RA21" is null and pr."AreaFactor21" is not null) OR (s."RA21" != pr."AreaFactor21"))
OR ((s."RA22" is not null and pr."AreaFactor22" is null) OR (s."RA22" is null and pr."AreaFactor22" is not null) OR (s."RA22" != pr."AreaFactor22"))
OR ((s."RA23" is not null and pr."AreaFactor23" is null) OR (s."RA23" is null and pr."AreaFactor23" is not null) OR (s."RA23" != pr."AreaFactor23"))
OR ((s."RA24" is not null and pr."AreaFactor24" is null) OR (s."RA24" is null and pr."AreaFactor24" is not null) OR (s."RA24" != pr."AreaFactor24"))
OR ((s."RA25" is not null and pr."AreaFactor25" is null) OR (s."RA25" is null and pr."AreaFactor25" is not null) OR (s."RA25" != pr."AreaFactor25"))
OR ((s."RA26" is not null and pr."AreaFactor26" is null) OR (s."RA26" is null and pr."AreaFactor26" is not null) OR (s."RA26" != pr."AreaFactor26"))
OR ((s."RA27" is not null and pr."AreaFactor27" is null) OR (s."RA27" is null and pr."AreaFactor27" is not null) OR (s."RA27" != pr."AreaFactor27"))
OR ((s."RA28" is not null and pr."AreaFactor28" is null) OR (s."RA28" is null and pr."AreaFactor28" is not null) OR (s."RA28" != pr."AreaFactor28"))
OR ((s."RA29" is not null and pr."AreaFactor29" is null) OR (s."RA29" is null and pr."AreaFactor29" is not null) OR (s."RA29" != pr."AreaFactor29"))
OR ((s."RA30" is not null and pr."AreaFactor30" is null) OR (s."RA30" is null and pr."AreaFactor30" is not null) OR (s."RA30" != pr."AreaFactor30"))
OR ((s."RA31" is not null and pr."AreaFactor31" is null) OR (s."RA31" is null and pr."AreaFactor31" is not null) OR (s."RA31" != pr."AreaFactor31"))
OR ((s."RA32" is not null and pr."AreaFactor32" is null) OR (s."RA32" is null and pr."AreaFactor32" is not null) OR (s."RA32" != pr."AreaFactor32"))
OR ((s."RA33" is not null and pr."AreaFactor33" is null) OR (s."RA33" is null and pr."AreaFactor33" is not null) OR (s."RA33" != pr."AreaFactor33"))
OR ((s."RA34" is not null and pr."AreaFactor34" is null) OR (s."RA34" is null and pr."AreaFactor34" is not null) OR (s."RA34" != pr."AreaFactor34"))
OR ((s."RA35" is not null and pr."AreaFactor35" is null) OR (s."RA35" is null and pr."AreaFactor35" is not null) OR (s."RA35" != pr."AreaFactor35"))
OR ((s."RA36" is not null and pr."AreaFactor36" is null) OR (s."RA36" is null and pr."AreaFactor36" is not null) OR (s."RA36" != pr."AreaFactor36"))
OR ((s."RA37" is not null and pr."AreaFactor37" is null) OR (s."RA37" is null and pr."AreaFactor37" is not null) OR (s."RA37" != pr."AreaFactor37"))
OR ((s."RA38" is not null and pr."AreaFactor38" is null) OR (s."RA38" is null and pr."AreaFactor38" is not null) OR (s."RA38" != pr."AreaFactor38"))
OR ((s."RA39" is not null and pr."AreaFactor39" is null) OR (s."RA39" is null and pr."AreaFactor39" is not null) OR (s."RA39" != pr."AreaFactor39"))
OR ((s."RA40" is not null and pr."AreaFactor40" is null) OR (s."RA40" is null and pr."AreaFactor40" is not null) OR (s."RA40" != pr."AreaFactor40"))
OR ((s."RA41" is not null and pr."AreaFactor41" is null) OR (s."RA41" is null and pr."AreaFactor41" is not null) OR (s."RA41" != pr."AreaFactor41"))
OR ((s."RA42" is not null and pr."AreaFactor42" is null) OR (s."RA42" is null and pr."AreaFactor42" is not null) OR (s."RA42" != pr."AreaFactor42"))
OR ((s."RA43" is not null and pr."AreaFactor43" is null) OR (s."RA43" is null and pr."AreaFactor43" is not null) OR (s."RA43" != pr."AreaFactor43"))
OR ((s."RA44" is not null and pr."AreaFactor44" is null) OR (s."RA44" is null and pr."AreaFactor44" is not null) OR (s."RA44" != pr."AreaFactor44"))
OR ((s."RA45" is not null and pr."AreaFactor45" is null) OR (s."RA45" is null and pr."AreaFactor45" is not null) OR (s."RA45" != pr."AreaFactor45"))
OR ((s."RA46" is not null and pr."AreaFactor46" is null) OR (s."RA46" is null and pr."AreaFactor46" is not null) OR (s."RA46" != pr."AreaFactor46"))
OR ((s."RA47" is not null and pr."AreaFactor47" is null) OR (s."RA47" is null and pr."AreaFactor47" is not null) OR (s."RA47" != pr."AreaFactor47"))
OR ((s."RA48" is not null and pr."AreaFactor48" is null) OR (s."RA48" is null and pr."AreaFactor48" is not null) OR (s."RA48" != pr."AreaFactor48"))
OR ((s."RA49" is not null and pr."AreaFactor49" is null) OR (s."RA49" is null and pr."AreaFactor49" is not null) OR (s."RA49" != pr."AreaFactor49"))
OR ((s."RA50" is not null and pr."AreaFactor50" is null) OR (s."RA50" is null and pr."AreaFactor50" is not null) OR (s."RA50" != pr."AreaFactor50"))
OR ((s."RA51" is not null and pr."AreaFactor51" is null) OR (s."RA51" is null and pr."AreaFactor51" is not null) OR (s."RA51" != pr."AreaFactor51"))
OR ((s."RA52" is not null and pr."AreaFactor52" is null) OR (s."RA52" is null and pr."AreaFactor52" is not null) OR (s."RA52" != pr."AreaFactor52"))
OR ((s."RA53" is not null and pr."AreaFactor53" is null) OR (s."RA53" is null and pr."AreaFactor53" is not null) OR (s."RA53" != pr."AreaFactor53"))
OR ((s."RA54" is not null and pr."AreaFactor54" is null) OR (s."RA54" is null and pr."AreaFactor54" is not null) OR (s."RA54" != pr."AreaFactor54"))
OR ((s."RA55" is not null and pr."AreaFactor55" is null) OR (s."RA55" is null and pr."AreaFactor55" is not null) OR (s."RA55" != pr."AreaFactor55"))
OR ((s."RA56" is not null and pr."AreaFactor56" is null) OR (s."RA56" is null and pr."AreaFactor56" is not null) OR (s."RA56" != pr."AreaFactor56"))
OR ((s."RA57" is not null and pr."AreaFactor57" is null) OR (s."RA57" is null and pr."AreaFactor57" is not null) OR (s."RA57" != pr."AreaFactor57"))
OR ((s."RA58" is not null and pr."AreaFactor58" is null) OR (s."RA58" is null and pr."AreaFactor58" is not null) OR (s."RA58" != pr."AreaFactor58"))
OR ((s."RA59" is not null and pr."AreaFactor59" is null) OR (s."RA59" is null and pr."AreaFactor59" is not null) OR (s."RA59" != pr."AreaFactor59"))
OR ((s."RA60" is not null and pr."AreaFactor60" is null) OR (s."RA60" is null and pr."AreaFactor60" is not null) OR (s."RA60" != pr."AreaFactor60"))
OR ((s."RA61" is not null and pr."AreaFactor61" is null) OR (s."RA61" is null and pr."AreaFactor61" is not null) OR (s."RA61" != pr."AreaFactor61"))
OR ((s."RA62" is not null and pr."AreaFactor62" is null) OR (s."RA62" is null and pr."AreaFactor62" is not null) OR (s."RA62" != pr."AreaFactor62"))
OR ((s."RA63" is not null and pr."AreaFactor63" is null) OR (s."RA63" is null and pr."AreaFactor63" is not null) OR (s."RA63" != pr."AreaFactor63"))
OR ((s."RA64" is not null and pr."AreaFactor64" is null) OR (s."RA64" is null and pr."AreaFactor64" is not null) OR (s."RA64" != pr."AreaFactor64"))
OR ((s."RA65" is not null and pr."AreaFactor65" is null) OR (s."RA65" is null and pr."AreaFactor65" is not null) OR (s."RA65" != pr."AreaFactor65"))
OR ((s."RA66" is not null and pr."AreaFactor66" is null) OR (s."RA66" is null and pr."AreaFactor66" is not null) OR (s."RA66" != pr."AreaFactor66"))
OR ((s."RA67" is not null and pr."AreaFactor67" is null) OR (s."RA67" is null and pr."AreaFactor67" is not null) OR (s."RA67" != pr."AreaFactor67"))
;

-- Backup
 
BEGIN;
 
-- backup
SELECT   p.*
INTO     public."Plans_05092018_BAK"
FROM     public.stage_planrates_rp502_oh_20180509 as s
INNER 
JOIN     public."Plans" as p ON  s."plan_year" = p."Year" 
                             AND s."HIOS Plan ID" = p."HiosPlanID"
                             AND s."State" = p."State"
;

SELECT   pr.*
INTO     public."PlanRates_05092018_BAK"
FROM     public.stage_planrates_rp502_oh_20180509 as s
INNER 
JOIN     public."Plans" as p ON  s."plan_year" = p."Year" 
                             AND s."HIOS Plan ID" = p."HiosPlanID"
                             AND s."State" = p."State"
INNER 
JOIN     public."PlanRates" as pr ON p."Year" = pr."Year" and p."HiosPlanID" = pr."HiosPlanID"
;

-- Counts of Backups - IF ZERO dont proceed
SELECT   COUNT(*) as "Plans_05092018_BAK_Count" FROM  public."Plans_05092018_BAK";
SELECT   COUNT(*) as "PlanRates_05092018_BAK_Count" FROM  public."PlanRates_05092018_BAK";

-- Update Plans
UPDATE  public."Plans" p
SET     "UpdatedDate" = current_timestamp
        ,"Carrier" = s."Carrier"
        ,"CarrierFriendlyName" = s."Carrier Marketing Name"

        ,"PlanDisplayName" = s."plan_name"
        ,"PlanType" = s."plan_type"
        ,"Metal" = s."level"
        ,"IsHSA" = s."HSA"
        ,"IsActive" = s."is_active"
        ,"IsForSale" = s."is_for_sale"
        ,"ServiceAreaID" = s."service_area_id"
FROM    public.stage_planrates_rp502_oh_20180509 as s
WHERE   s."plan_year" = p."Year" 
AND     s."HIOS Plan ID" = p."HiosPlanID"
AND     s."State" = p."State"
AND     (
           (1 = 0)
        OR ((s."Carrier" is not null and p."Carrier" is null) OR (s."Carrier" is null and p."Carrier" is not null) OR (s."Carrier" != p."Carrier"))
        OR ((s."Carrier Marketing Name" is not null and p."CarrierFriendlyName" is null) OR (s."Carrier Marketing Name" is null and p."CarrierFriendlyName" is not null) OR (s."Carrier Marketing Name" != p."CarrierFriendlyName"))
        OR ((s."plan_name" is not null and p."PlanDisplayName" is null) OR (s."plan_name" is null and p."PlanDisplayName" is not null) OR (s."plan_name" != p."PlanDisplayName"))
        OR ((s."plan_type" is not null and p."PlanType" is null) OR (s."plan_type" is null and p."PlanType" is not null) OR (s."plan_type" != p."PlanType"))
        OR ((s."level" is not null and p."Metal" is null) OR (s."level" is null and p."Metal" is not null) OR (s."level" != p."Metal"))
        OR ((s."HSA" is not null and p."IsHSA" is null) OR (s."HSA" is null and p."IsHSA" is not null) OR (s."HSA" != p."IsHSA"))
        OR ((s."is_active" is not null and p."IsActive" is null) OR (s."is_active" is null and p."IsActive" is not null) OR (s."is_active" != p."IsActive"))
        OR ((s."is_for_sale" is not null and p."IsForSale" is null) OR (s."is_for_sale" is null and p."IsForSale" is not null) OR (s."is_for_sale" != p."IsForSale"))
        OR ((s."service_area_id" is not null and p."ServiceAreaID" is null) OR (s."service_area_id" is null and p."ServiceAreaID" is not null) OR (s."service_area_id" != p."ServiceAreaID"))
        )
;

-- INSERT NEW Plans
INSERT INTO
        public."Plans"
        (
        "Year"
        ,"HiosPlanID"
        ,"PlanMarketingName"
        ,"PlanDisplayName"
        ,"State"
        ,"Carrier"
        ,"CarrierFriendlyName"
        ,"PlanType"
        ,"Metal"
        ,"ServiceAreaID"
        ,"IsActive"
        ,"IsForSale"
        ,"IsHSA"
        ,"UseForModeling"
        ,"PlanCollectionStatus"
        ,"GroupDisclaimer"
        ,"HixmeCoinsurance"
        ,"CreatedDate"
        ,"UpdatedDate"
        )
SELECT   DISTINCT
         s."plan_year" as "Year"
        ,s."HIOS Plan ID" as "HiosPlanID"
        ,s."plan_name" as "PlanMarketingName"
        ,s."plan_name" as "PlanDisplayName"
        ,s."State" as "State"
        ,s."Carrier" as "Carrier"
        ,s."Carrier Marketing Name" as "CarrierFriendlyName"
        ,s."plan_type" as "PlanType"
        ,s."level" as "Metal"
        ,s."service_area_id" as "ServiceAreaID"
        ,s."is_active" as "IsActive"
        ,s."is_for_sale" as "IsForSale"
        ,s."HSA" as "IsHSA"
        ,s."use_for_modeling" as "UseForModeling"
        ,'' as "PlanCollectionStatus"
        ,'' as "GroupDisclaimer"
        ,0.00  as "HixmeCoinsurance"
        ,current_timestamp as "CreatedDate"
        ,current_timestamp as "UpdatedDate"
FROM     public.stage_planrates_rp502_oh_20180509 as s
WHERE    NOT EXISTS (SELECT 1 FROM "Plans" as p WHERE s."plan_year" = p."Year" and s."HIOS Plan ID" = p."HiosPlanID" AND s."State" = p."State")
;

-- Update Plan Rates
UPDATE   public."PlanRates" pr
SET      "UpdatedDate" = current_timestamp
        ,"BaseRate" = s."BaseRate"
        ,"AreaFactor01" = s."RA01"
        ,"AreaFactor02" = s."RA02"
        ,"AreaFactor03" = s."RA03"
        ,"AreaFactor04" = s."RA04"
        ,"AreaFactor05" = s."RA05"
        ,"AreaFactor06" = s."RA06"
        ,"AreaFactor07" = s."RA07"
        ,"AreaFactor08" = s."RA08"
        ,"AreaFactor09" = s."RA09"
        ,"AreaFactor10" = s."RA10"
        ,"AreaFactor11" = s."RA11"
        ,"AreaFactor12" = s."RA12"
        ,"AreaFactor13" = s."RA13"
        ,"AreaFactor14" = s."RA14"
        ,"AreaFactor15" = s."RA15"
        ,"AreaFactor16" = s."RA16"
        ,"AreaFactor17" = s."RA17"
        ,"AreaFactor18" = s."RA18"
        ,"AreaFactor19" = s."RA19"
        ,"AreaFactor20" = s."RA20"
        ,"AreaFactor21" = s."RA21"
        ,"AreaFactor22" = s."RA22"
        ,"AreaFactor23" = s."RA23"
        ,"AreaFactor24" = s."RA24"
        ,"AreaFactor25" = s."RA25"
        ,"AreaFactor26" = s."RA26"
        ,"AreaFactor27" = s."RA27"
        ,"AreaFactor28" = s."RA28"
        ,"AreaFactor29" = s."RA29"
        ,"AreaFactor30" = s."RA30"
        ,"AreaFactor31" = s."RA31"
        ,"AreaFactor32" = s."RA32"
        ,"AreaFactor33" = s."RA33"
        ,"AreaFactor34" = s."RA34"
        ,"AreaFactor35" = s."RA35"
        ,"AreaFactor36" = s."RA36"
        ,"AreaFactor37" = s."RA37"
        ,"AreaFactor38" = s."RA38"
        ,"AreaFactor39" = s."RA39"
        ,"AreaFactor40" = s."RA40"
        ,"AreaFactor41" = s."RA41"
        ,"AreaFactor42" = s."RA42"
        ,"AreaFactor43" = s."RA43"
        ,"AreaFactor44" = s."RA44"
        ,"AreaFactor45" = s."RA45"
        ,"AreaFactor46" = s."RA46"
        ,"AreaFactor47" = s."RA47"
        ,"AreaFactor48" = s."RA48"
        ,"AreaFactor49" = s."RA49"
        ,"AreaFactor50" = s."RA50"
        ,"AreaFactor51" = s."RA51"
        ,"AreaFactor52" = s."RA52"
        ,"AreaFactor53" = s."RA53"
        ,"AreaFactor54" = s."RA54"
        ,"AreaFactor55" = s."RA55"
        ,"AreaFactor56" = s."RA56"
        ,"AreaFactor57" = s."RA57"
        ,"AreaFactor58" = s."RA58"
        ,"AreaFactor59" = s."RA59"
        ,"AreaFactor60" = s."RA60"
        ,"AreaFactor61" = s."RA61"
        ,"AreaFactor62" = s."RA62"
        ,"AreaFactor63" = s."RA63"
        ,"AreaFactor64" = s."RA64"
        ,"AreaFactor65" = s."RA65"
        ,"AreaFactor66" = s."RA66"
        ,"AreaFactor67" = s."RA67"
FROM     public."Plans" as p
INNER 
JOIN     public.stage_planrates_rp502_oh_20180509 as s   ON  s."plan_year"       = p."Year" 
                                                AND s."HIOS Plan ID"    = p."HiosPlanID"
                                                AND s."State"           = p."State"
WHERE   p."Year"        = pr."Year"
AND     p."HiosPlanID"  = pr."HiosPlanID"
AND     (
           (1 = 0)
        OR ((s."BaseRate" is not null and pr."BaseRate" is null) OR (s."BaseRate" is null and pr."BaseRate" is not null) OR (s."BaseRate" != pr."BaseRate"))
        OR ((s."RA01" is not null and pr."AreaFactor01" is null) OR (s."RA01" is null and pr."AreaFactor01" is not null) OR (s."RA01" != pr."AreaFactor01"))
        OR ((s."RA02" is not null and pr."AreaFactor02" is null) OR (s."RA02" is null and pr."AreaFactor02" is not null) OR (s."RA02" != pr."AreaFactor02"))
        OR ((s."RA03" is not null and pr."AreaFactor03" is null) OR (s."RA03" is null and pr."AreaFactor03" is not null) OR (s."RA03" != pr."AreaFactor03"))
        OR ((s."RA04" is not null and pr."AreaFactor04" is null) OR (s."RA04" is null and pr."AreaFactor04" is not null) OR (s."RA04" != pr."AreaFactor04"))
        OR ((s."RA05" is not null and pr."AreaFactor05" is null) OR (s."RA05" is null and pr."AreaFactor05" is not null) OR (s."RA05" != pr."AreaFactor05"))
        OR ((s."RA06" is not null and pr."AreaFactor06" is null) OR (s."RA06" is null and pr."AreaFactor06" is not null) OR (s."RA06" != pr."AreaFactor06"))
        OR ((s."RA07" is not null and pr."AreaFactor07" is null) OR (s."RA07" is null and pr."AreaFactor07" is not null) OR (s."RA07" != pr."AreaFactor07"))
        OR ((s."RA08" is not null and pr."AreaFactor08" is null) OR (s."RA08" is null and pr."AreaFactor08" is not null) OR (s."RA08" != pr."AreaFactor08"))
        OR ((s."RA09" is not null and pr."AreaFactor09" is null) OR (s."RA09" is null and pr."AreaFactor09" is not null) OR (s."RA09" != pr."AreaFactor09"))
        OR ((s."RA10" is not null and pr."AreaFactor10" is null) OR (s."RA10" is null and pr."AreaFactor10" is not null) OR (s."RA10" != pr."AreaFactor10"))
        OR ((s."RA11" is not null and pr."AreaFactor11" is null) OR (s."RA11" is null and pr."AreaFactor11" is not null) OR (s."RA11" != pr."AreaFactor11"))
        OR ((s."RA12" is not null and pr."AreaFactor12" is null) OR (s."RA12" is null and pr."AreaFactor12" is not null) OR (s."RA12" != pr."AreaFactor12"))
        OR ((s."RA13" is not null and pr."AreaFactor13" is null) OR (s."RA13" is null and pr."AreaFactor13" is not null) OR (s."RA13" != pr."AreaFactor13"))
        OR ((s."RA14" is not null and pr."AreaFactor14" is null) OR (s."RA14" is null and pr."AreaFactor14" is not null) OR (s."RA14" != pr."AreaFactor14"))
        OR ((s."RA15" is not null and pr."AreaFactor15" is null) OR (s."RA15" is null and pr."AreaFactor15" is not null) OR (s."RA15" != pr."AreaFactor15"))
        OR ((s."RA16" is not null and pr."AreaFactor16" is null) OR (s."RA16" is null and pr."AreaFactor16" is not null) OR (s."RA16" != pr."AreaFactor16"))
        OR ((s."RA17" is not null and pr."AreaFactor17" is null) OR (s."RA17" is null and pr."AreaFactor17" is not null) OR (s."RA17" != pr."AreaFactor17"))
        OR ((s."RA18" is not null and pr."AreaFactor18" is null) OR (s."RA18" is null and pr."AreaFactor18" is not null) OR (s."RA18" != pr."AreaFactor18"))
        OR ((s."RA19" is not null and pr."AreaFactor19" is null) OR (s."RA19" is null and pr."AreaFactor19" is not null) OR (s."RA19" != pr."AreaFactor19"))
        OR ((s."RA20" is not null and pr."AreaFactor20" is null) OR (s."RA20" is null and pr."AreaFactor20" is not null) OR (s."RA20" != pr."AreaFactor20"))
        OR ((s."RA21" is not null and pr."AreaFactor21" is null) OR (s."RA21" is null and pr."AreaFactor21" is not null) OR (s."RA21" != pr."AreaFactor21"))
        OR ((s."RA22" is not null and pr."AreaFactor22" is null) OR (s."RA22" is null and pr."AreaFactor22" is not null) OR (s."RA22" != pr."AreaFactor22"))
        OR ((s."RA23" is not null and pr."AreaFactor23" is null) OR (s."RA23" is null and pr."AreaFactor23" is not null) OR (s."RA23" != pr."AreaFactor23"))
        OR ((s."RA24" is not null and pr."AreaFactor24" is null) OR (s."RA24" is null and pr."AreaFactor24" is not null) OR (s."RA24" != pr."AreaFactor24"))
        OR ((s."RA25" is not null and pr."AreaFactor25" is null) OR (s."RA25" is null and pr."AreaFactor25" is not null) OR (s."RA25" != pr."AreaFactor25"))
        OR ((s."RA26" is not null and pr."AreaFactor26" is null) OR (s."RA26" is null and pr."AreaFactor26" is not null) OR (s."RA26" != pr."AreaFactor26"))
        OR ((s."RA27" is not null and pr."AreaFactor27" is null) OR (s."RA27" is null and pr."AreaFactor27" is not null) OR (s."RA27" != pr."AreaFactor27"))
        OR ((s."RA28" is not null and pr."AreaFactor28" is null) OR (s."RA28" is null and pr."AreaFactor28" is not null) OR (s."RA28" != pr."AreaFactor28"))
        OR ((s."RA29" is not null and pr."AreaFactor29" is null) OR (s."RA29" is null and pr."AreaFactor29" is not null) OR (s."RA29" != pr."AreaFactor29"))
        OR ((s."RA30" is not null and pr."AreaFactor30" is null) OR (s."RA30" is null and pr."AreaFactor30" is not null) OR (s."RA30" != pr."AreaFactor30"))
        OR ((s."RA31" is not null and pr."AreaFactor31" is null) OR (s."RA31" is null and pr."AreaFactor31" is not null) OR (s."RA31" != pr."AreaFactor31"))
        OR ((s."RA32" is not null and pr."AreaFactor32" is null) OR (s."RA32" is null and pr."AreaFactor32" is not null) OR (s."RA32" != pr."AreaFactor32"))
        OR ((s."RA33" is not null and pr."AreaFactor33" is null) OR (s."RA33" is null and pr."AreaFactor33" is not null) OR (s."RA33" != pr."AreaFactor33"))
        OR ((s."RA34" is not null and pr."AreaFactor34" is null) OR (s."RA34" is null and pr."AreaFactor34" is not null) OR (s."RA34" != pr."AreaFactor34"))
        OR ((s."RA35" is not null and pr."AreaFactor35" is null) OR (s."RA35" is null and pr."AreaFactor35" is not null) OR (s."RA35" != pr."AreaFactor35"))
        OR ((s."RA36" is not null and pr."AreaFactor36" is null) OR (s."RA36" is null and pr."AreaFactor36" is not null) OR (s."RA36" != pr."AreaFactor36"))
        OR ((s."RA37" is not null and pr."AreaFactor37" is null) OR (s."RA37" is null and pr."AreaFactor37" is not null) OR (s."RA37" != pr."AreaFactor37"))
        OR ((s."RA38" is not null and pr."AreaFactor38" is null) OR (s."RA38" is null and pr."AreaFactor38" is not null) OR (s."RA38" != pr."AreaFactor38"))
        OR ((s."RA39" is not null and pr."AreaFactor39" is null) OR (s."RA39" is null and pr."AreaFactor39" is not null) OR (s."RA39" != pr."AreaFactor39"))
        OR ((s."RA40" is not null and pr."AreaFactor40" is null) OR (s."RA40" is null and pr."AreaFactor40" is not null) OR (s."RA40" != pr."AreaFactor40"))
        OR ((s."RA41" is not null and pr."AreaFactor41" is null) OR (s."RA41" is null and pr."AreaFactor41" is not null) OR (s."RA41" != pr."AreaFactor41"))
        OR ((s."RA42" is not null and pr."AreaFactor42" is null) OR (s."RA42" is null and pr."AreaFactor42" is not null) OR (s."RA42" != pr."AreaFactor42"))
        OR ((s."RA43" is not null and pr."AreaFactor43" is null) OR (s."RA43" is null and pr."AreaFactor43" is not null) OR (s."RA43" != pr."AreaFactor43"))
        OR ((s."RA44" is not null and pr."AreaFactor44" is null) OR (s."RA44" is null and pr."AreaFactor44" is not null) OR (s."RA44" != pr."AreaFactor44"))
        OR ((s."RA45" is not null and pr."AreaFactor45" is null) OR (s."RA45" is null and pr."AreaFactor45" is not null) OR (s."RA45" != pr."AreaFactor45"))
        OR ((s."RA46" is not null and pr."AreaFactor46" is null) OR (s."RA46" is null and pr."AreaFactor46" is not null) OR (s."RA46" != pr."AreaFactor46"))
        OR ((s."RA47" is not null and pr."AreaFactor47" is null) OR (s."RA47" is null and pr."AreaFactor47" is not null) OR (s."RA47" != pr."AreaFactor47"))
        OR ((s."RA48" is not null and pr."AreaFactor48" is null) OR (s."RA48" is null and pr."AreaFactor48" is not null) OR (s."RA48" != pr."AreaFactor48"))
        OR ((s."RA49" is not null and pr."AreaFactor49" is null) OR (s."RA49" is null and pr."AreaFactor49" is not null) OR (s."RA49" != pr."AreaFactor49"))
        OR ((s."RA50" is not null and pr."AreaFactor50" is null) OR (s."RA50" is null and pr."AreaFactor50" is not null) OR (s."RA50" != pr."AreaFactor50"))
        OR ((s."RA51" is not null and pr."AreaFactor51" is null) OR (s."RA51" is null and pr."AreaFactor51" is not null) OR (s."RA51" != pr."AreaFactor51"))
        OR ((s."RA52" is not null and pr."AreaFactor52" is null) OR (s."RA52" is null and pr."AreaFactor52" is not null) OR (s."RA52" != pr."AreaFactor52"))
        OR ((s."RA53" is not null and pr."AreaFactor53" is null) OR (s."RA53" is null and pr."AreaFactor53" is not null) OR (s."RA53" != pr."AreaFactor53"))
        OR ((s."RA54" is not null and pr."AreaFactor54" is null) OR (s."RA54" is null and pr."AreaFactor54" is not null) OR (s."RA54" != pr."AreaFactor54"))
        OR ((s."RA55" is not null and pr."AreaFactor55" is null) OR (s."RA55" is null and pr."AreaFactor55" is not null) OR (s."RA55" != pr."AreaFactor55"))
        OR ((s."RA56" is not null and pr."AreaFactor56" is null) OR (s."RA56" is null and pr."AreaFactor56" is not null) OR (s."RA56" != pr."AreaFactor56"))
        OR ((s."RA57" is not null and pr."AreaFactor57" is null) OR (s."RA57" is null and pr."AreaFactor57" is not null) OR (s."RA57" != pr."AreaFactor57"))
        OR ((s."RA58" is not null and pr."AreaFactor58" is null) OR (s."RA58" is null and pr."AreaFactor58" is not null) OR (s."RA58" != pr."AreaFactor58"))
        OR ((s."RA59" is not null and pr."AreaFactor59" is null) OR (s."RA59" is null and pr."AreaFactor59" is not null) OR (s."RA59" != pr."AreaFactor59"))
        OR ((s."RA60" is not null and pr."AreaFactor60" is null) OR (s."RA60" is null and pr."AreaFactor60" is not null) OR (s."RA60" != pr."AreaFactor60"))
        OR ((s."RA61" is not null and pr."AreaFactor61" is null) OR (s."RA61" is null and pr."AreaFactor61" is not null) OR (s."RA61" != pr."AreaFactor61"))
        OR ((s."RA62" is not null and pr."AreaFactor62" is null) OR (s."RA62" is null and pr."AreaFactor62" is not null) OR (s."RA62" != pr."AreaFactor62"))
        OR ((s."RA63" is not null and pr."AreaFactor63" is null) OR (s."RA63" is null and pr."AreaFactor63" is not null) OR (s."RA63" != pr."AreaFactor63"))
        OR ((s."RA64" is not null and pr."AreaFactor64" is null) OR (s."RA64" is null and pr."AreaFactor64" is not null) OR (s."RA64" != pr."AreaFactor64"))
        OR ((s."RA65" is not null and pr."AreaFactor65" is null) OR (s."RA65" is null and pr."AreaFactor65" is not null) OR (s."RA65" != pr."AreaFactor65"))
        OR ((s."RA66" is not null and pr."AreaFactor66" is null) OR (s."RA66" is null and pr."AreaFactor66" is not null) OR (s."RA66" != pr."AreaFactor66"))
        OR ((s."RA67" is not null and pr."AreaFactor67" is null) OR (s."RA67" is null and pr."AreaFactor67" is not null) OR (s."RA67" != pr."AreaFactor67"))
        )
;

-- Insert Rates
INSERT INTO "PlanRates"
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
        )
SELECT   p."Year"
        ,p."HiosPlanID"
        ,s."BaseRate" as "BaseRate"
        ,s."RA01" as "AreaFactor01"
        ,s."RA02" as "AreaFactor02"
        ,s."RA03" as "AreaFactor03"
        ,s."RA04" as "AreaFactor04"
        ,s."RA05" as "AreaFactor05"
        ,s."RA06" as "AreaFactor06"
        ,s."RA07" as "AreaFactor07"
        ,s."RA08" as "AreaFactor08"
        ,s."RA09" as "AreaFactor09"
        ,s."RA10" as "AreaFactor10"
        ,s."RA11" as "AreaFactor11"
        ,s."RA12" as "AreaFactor12"
        ,s."RA13" as "AreaFactor13"
        ,s."RA14" as "AreaFactor14"
        ,s."RA15" as "AreaFactor15"
        ,s."RA16" as "AreaFactor16"
        ,s."RA17" as "AreaFactor17"
        ,s."RA18" as "AreaFactor18"
        ,s."RA19" as "AreaFactor19"
        ,s."RA20" as "AreaFactor20"
        ,s."RA21" as "AreaFactor21"
        ,s."RA22" as "AreaFactor22"
        ,s."RA23" as "AreaFactor23"
        ,s."RA24" as "AreaFactor24"
        ,s."RA25" as "AreaFactor25"
        ,s."RA26" as "AreaFactor26"
        ,s."RA27" as "AreaFactor27"
        ,s."RA28" as "AreaFactor28"
        ,s."RA29" as "AreaFactor29"
        ,s."RA30" as "AreaFactor30"
        ,s."RA31" as "AreaFactor31"
        ,s."RA32" as "AreaFactor32"
        ,s."RA33" as "AreaFactor33"
        ,s."RA34" as "AreaFactor34"
        ,s."RA35" as "AreaFactor35"
        ,s."RA36" as "AreaFactor36"
        ,s."RA37" as "AreaFactor37"
        ,s."RA38" as "AreaFactor38"
        ,s."RA39" as "AreaFactor39"
        ,s."RA40" as "AreaFactor40"
        ,s."RA41" as "AreaFactor41"
        ,s."RA42" as "AreaFactor42"
        ,s."RA43" as "AreaFactor43"
        ,s."RA44" as "AreaFactor44"
        ,s."RA45" as "AreaFactor45"
        ,s."RA46" as "AreaFactor46"
        ,s."RA47" as "AreaFactor47"
        ,s."RA48" as "AreaFactor48"
        ,s."RA49" as "AreaFactor49"
        ,s."RA50" as "AreaFactor50"
        ,s."RA51" as "AreaFactor51"
        ,s."RA52" as "AreaFactor52"
        ,s."RA53" as "AreaFactor53"
        ,s."RA54" as "AreaFactor54"
        ,s."RA55" as "AreaFactor55"
        ,s."RA56" as "AreaFactor56"
        ,s."RA57" as "AreaFactor57"
        ,s."RA58" as "AreaFactor58"
        ,s."RA59" as "AreaFactor59"
        ,s."RA60" as "AreaFactor60"
        ,s."RA61" as "AreaFactor61"
        ,s."RA62" as "AreaFactor62"
        ,s."RA63" as "AreaFactor63"
        ,s."RA64" as "AreaFactor64"
        ,s."RA65" as "AreaFactor65"
        ,s."RA66" as "AreaFactor66"
        ,s."RA67" as "AreaFactor67"
        ,1.278000 as "FourtyYearOldFactor"
        ,current_timestamp as "CreatedDate"
        ,current_timestamp as "UpdatedDate"
FROM     public."Plans" as p
INNER 
JOIN     public.stage_planrates_rp502_oh_20180509 as s   ON  s."plan_year"       = p."Year" 
                                                AND s."HIOS Plan ID"    = p."HiosPlanID"
                                                AND s."State"           = p."State"
WHERE   1 = 1
AND     NOT EXISTS (SELECT 1 FROM "PlanRates" as pr WHERE pr."Year" = p."Year" AND pr."HiosPlanID" = p."HiosPlanID")
;

-- Verfiy Update
-- Plans
SELECT   COUNT(*) as "Plans_AfterUpdate_EQ0" -- Should be Zero or else Rollback
FROM     public.stage_planrates_rp502_oh_20180509 as s
INNER 
JOIN     public."Plans" as p ON  s."plan_year" = p."Year" 
                             AND s."HIOS Plan ID" = p."HiosPlanID"
                             AND s."State" = p."State"
WHERE    1 = 0
OR ((s."Carrier" is not null and p."Carrier" is null) OR (s."Carrier" is null and p."Carrier" is not null) OR (s."Carrier" != p."Carrier"))
OR ((s."Carrier Marketing Name" is not null and p."CarrierFriendlyName" is null) OR (s."Carrier Marketing Name" is null and p."CarrierFriendlyName" is not null) OR (s."Carrier Marketing Name" != p."CarrierFriendlyName"))
OR ((s."plan_name" is not null and p."PlanDisplayName" is null) OR (s."plan_name" is null and p."PlanDisplayName" is not null) OR (s."plan_name" != p."PlanDisplayName"))
OR ((s."plan_type" is not null and p."PlanType" is null) OR (s."plan_type" is null and p."PlanType" is not null) OR (s."plan_type" != p."PlanType"))
OR ((s."level" is not null and p."Metal" is null) OR (s."level" is null and p."Metal" is not null) OR (s."level" != p."Metal"))
OR ((s."HSA" is not null and p."IsHSA" is null) OR (s."HSA" is null and p."IsHSA" is not null) OR (s."HSA" != p."IsHSA"))
OR ((s."is_active" is not null and p."IsActive" is null) OR (s."is_active" is null and p."IsActive" is not null) OR (s."is_active" != p."IsActive"))
OR ((s."is_for_sale" is not null and p."IsForSale" is null) OR (s."is_for_sale" is null and p."IsForSale" is not null) OR (s."is_for_sale" != p."IsForSale"))
OR ((s."service_area_id" is not null and p."ServiceAreaID" is null) OR (s."service_area_id" is null and p."ServiceAreaID" is not null) OR (s."service_area_id" != p."ServiceAreaID"))
;

-- Plan Rates
SELECT   COUNT(*) as "PlanRates_AfterUpdate_EQ0" -- Should be Zero or else ROLLBACK
FROM     public.stage_planrates_rp502_oh_20180509 as s
INNER 
JOIN     public."Plans" as p ON  s."plan_year" = p."Year" 
                             AND s."HIOS Plan ID" = p."HiosPlanID"
                             AND s."State" = p."State"
INNER 
JOIN     public."PlanRates" as pr ON p."Year" = pr."Year" and p."HiosPlanID" = pr."HiosPlanID"
WHERE    1 = 0
OR ((s."BaseRate" is not null and pr."BaseRate" is null) OR (s."BaseRate" is null and pr."BaseRate" is not null) OR (s."BaseRate" != pr."BaseRate"))
OR ((s."RA01" is not null and pr."AreaFactor01" is null) OR (s."RA01" is null and pr."AreaFactor01" is not null) OR (s."RA01" != pr."AreaFactor01"))
OR ((s."RA02" is not null and pr."AreaFactor02" is null) OR (s."RA02" is null and pr."AreaFactor02" is not null) OR (s."RA02" != pr."AreaFactor02"))
OR ((s."RA03" is not null and pr."AreaFactor03" is null) OR (s."RA03" is null and pr."AreaFactor03" is not null) OR (s."RA03" != pr."AreaFactor03"))
OR ((s."RA04" is not null and pr."AreaFactor04" is null) OR (s."RA04" is null and pr."AreaFactor04" is not null) OR (s."RA04" != pr."AreaFactor04"))
OR ((s."RA05" is not null and pr."AreaFactor05" is null) OR (s."RA05" is null and pr."AreaFactor05" is not null) OR (s."RA05" != pr."AreaFactor05"))
OR ((s."RA06" is not null and pr."AreaFactor06" is null) OR (s."RA06" is null and pr."AreaFactor06" is not null) OR (s."RA06" != pr."AreaFactor06"))
OR ((s."RA07" is not null and pr."AreaFactor07" is null) OR (s."RA07" is null and pr."AreaFactor07" is not null) OR (s."RA07" != pr."AreaFactor07"))
OR ((s."RA08" is not null and pr."AreaFactor08" is null) OR (s."RA08" is null and pr."AreaFactor08" is not null) OR (s."RA08" != pr."AreaFactor08"))
OR ((s."RA09" is not null and pr."AreaFactor09" is null) OR (s."RA09" is null and pr."AreaFactor09" is not null) OR (s."RA09" != pr."AreaFactor09"))
OR ((s."RA10" is not null and pr."AreaFactor10" is null) OR (s."RA10" is null and pr."AreaFactor10" is not null) OR (s."RA10" != pr."AreaFactor10"))
OR ((s."RA11" is not null and pr."AreaFactor11" is null) OR (s."RA11" is null and pr."AreaFactor11" is not null) OR (s."RA11" != pr."AreaFactor11"))
OR ((s."RA12" is not null and pr."AreaFactor12" is null) OR (s."RA12" is null and pr."AreaFactor12" is not null) OR (s."RA12" != pr."AreaFactor12"))
OR ((s."RA13" is not null and pr."AreaFactor13" is null) OR (s."RA13" is null and pr."AreaFactor13" is not null) OR (s."RA13" != pr."AreaFactor13"))
OR ((s."RA14" is not null and pr."AreaFactor14" is null) OR (s."RA14" is null and pr."AreaFactor14" is not null) OR (s."RA14" != pr."AreaFactor14"))
OR ((s."RA15" is not null and pr."AreaFactor15" is null) OR (s."RA15" is null and pr."AreaFactor15" is not null) OR (s."RA15" != pr."AreaFactor15"))
OR ((s."RA16" is not null and pr."AreaFactor16" is null) OR (s."RA16" is null and pr."AreaFactor16" is not null) OR (s."RA16" != pr."AreaFactor16"))
OR ((s."RA17" is not null and pr."AreaFactor17" is null) OR (s."RA17" is null and pr."AreaFactor17" is not null) OR (s."RA17" != pr."AreaFactor17"))
OR ((s."RA18" is not null and pr."AreaFactor18" is null) OR (s."RA18" is null and pr."AreaFactor18" is not null) OR (s."RA18" != pr."AreaFactor18"))
OR ((s."RA19" is not null and pr."AreaFactor19" is null) OR (s."RA19" is null and pr."AreaFactor19" is not null) OR (s."RA19" != pr."AreaFactor19"))
OR ((s."RA20" is not null and pr."AreaFactor20" is null) OR (s."RA20" is null and pr."AreaFactor20" is not null) OR (s."RA20" != pr."AreaFactor20"))
OR ((s."RA21" is not null and pr."AreaFactor21" is null) OR (s."RA21" is null and pr."AreaFactor21" is not null) OR (s."RA21" != pr."AreaFactor21"))
OR ((s."RA22" is not null and pr."AreaFactor22" is null) OR (s."RA22" is null and pr."AreaFactor22" is not null) OR (s."RA22" != pr."AreaFactor22"))
OR ((s."RA23" is not null and pr."AreaFactor23" is null) OR (s."RA23" is null and pr."AreaFactor23" is not null) OR (s."RA23" != pr."AreaFactor23"))
OR ((s."RA24" is not null and pr."AreaFactor24" is null) OR (s."RA24" is null and pr."AreaFactor24" is not null) OR (s."RA24" != pr."AreaFactor24"))
OR ((s."RA25" is not null and pr."AreaFactor25" is null) OR (s."RA25" is null and pr."AreaFactor25" is not null) OR (s."RA25" != pr."AreaFactor25"))
OR ((s."RA26" is not null and pr."AreaFactor26" is null) OR (s."RA26" is null and pr."AreaFactor26" is not null) OR (s."RA26" != pr."AreaFactor26"))
OR ((s."RA27" is not null and pr."AreaFactor27" is null) OR (s."RA27" is null and pr."AreaFactor27" is not null) OR (s."RA27" != pr."AreaFactor27"))
OR ((s."RA28" is not null and pr."AreaFactor28" is null) OR (s."RA28" is null and pr."AreaFactor28" is not null) OR (s."RA28" != pr."AreaFactor28"))
OR ((s."RA29" is not null and pr."AreaFactor29" is null) OR (s."RA29" is null and pr."AreaFactor29" is not null) OR (s."RA29" != pr."AreaFactor29"))
OR ((s."RA30" is not null and pr."AreaFactor30" is null) OR (s."RA30" is null and pr."AreaFactor30" is not null) OR (s."RA30" != pr."AreaFactor30"))
OR ((s."RA31" is not null and pr."AreaFactor31" is null) OR (s."RA31" is null and pr."AreaFactor31" is not null) OR (s."RA31" != pr."AreaFactor31"))
OR ((s."RA32" is not null and pr."AreaFactor32" is null) OR (s."RA32" is null and pr."AreaFactor32" is not null) OR (s."RA32" != pr."AreaFactor32"))
OR ((s."RA33" is not null and pr."AreaFactor33" is null) OR (s."RA33" is null and pr."AreaFactor33" is not null) OR (s."RA33" != pr."AreaFactor33"))
OR ((s."RA34" is not null and pr."AreaFactor34" is null) OR (s."RA34" is null and pr."AreaFactor34" is not null) OR (s."RA34" != pr."AreaFactor34"))
OR ((s."RA35" is not null and pr."AreaFactor35" is null) OR (s."RA35" is null and pr."AreaFactor35" is not null) OR (s."RA35" != pr."AreaFactor35"))
OR ((s."RA36" is not null and pr."AreaFactor36" is null) OR (s."RA36" is null and pr."AreaFactor36" is not null) OR (s."RA36" != pr."AreaFactor36"))
OR ((s."RA37" is not null and pr."AreaFactor37" is null) OR (s."RA37" is null and pr."AreaFactor37" is not null) OR (s."RA37" != pr."AreaFactor37"))
OR ((s."RA38" is not null and pr."AreaFactor38" is null) OR (s."RA38" is null and pr."AreaFactor38" is not null) OR (s."RA38" != pr."AreaFactor38"))
OR ((s."RA39" is not null and pr."AreaFactor39" is null) OR (s."RA39" is null and pr."AreaFactor39" is not null) OR (s."RA39" != pr."AreaFactor39"))
OR ((s."RA40" is not null and pr."AreaFactor40" is null) OR (s."RA40" is null and pr."AreaFactor40" is not null) OR (s."RA40" != pr."AreaFactor40"))
OR ((s."RA41" is not null and pr."AreaFactor41" is null) OR (s."RA41" is null and pr."AreaFactor41" is not null) OR (s."RA41" != pr."AreaFactor41"))
OR ((s."RA42" is not null and pr."AreaFactor42" is null) OR (s."RA42" is null and pr."AreaFactor42" is not null) OR (s."RA42" != pr."AreaFactor42"))
OR ((s."RA43" is not null and pr."AreaFactor43" is null) OR (s."RA43" is null and pr."AreaFactor43" is not null) OR (s."RA43" != pr."AreaFactor43"))
OR ((s."RA44" is not null and pr."AreaFactor44" is null) OR (s."RA44" is null and pr."AreaFactor44" is not null) OR (s."RA44" != pr."AreaFactor44"))
OR ((s."RA45" is not null and pr."AreaFactor45" is null) OR (s."RA45" is null and pr."AreaFactor45" is not null) OR (s."RA45" != pr."AreaFactor45"))
OR ((s."RA46" is not null and pr."AreaFactor46" is null) OR (s."RA46" is null and pr."AreaFactor46" is not null) OR (s."RA46" != pr."AreaFactor46"))
OR ((s."RA47" is not null and pr."AreaFactor47" is null) OR (s."RA47" is null and pr."AreaFactor47" is not null) OR (s."RA47" != pr."AreaFactor47"))
OR ((s."RA48" is not null and pr."AreaFactor48" is null) OR (s."RA48" is null and pr."AreaFactor48" is not null) OR (s."RA48" != pr."AreaFactor48"))
OR ((s."RA49" is not null and pr."AreaFactor49" is null) OR (s."RA49" is null and pr."AreaFactor49" is not null) OR (s."RA49" != pr."AreaFactor49"))
OR ((s."RA50" is not null and pr."AreaFactor50" is null) OR (s."RA50" is null and pr."AreaFactor50" is not null) OR (s."RA50" != pr."AreaFactor50"))
OR ((s."RA51" is not null and pr."AreaFactor51" is null) OR (s."RA51" is null and pr."AreaFactor51" is not null) OR (s."RA51" != pr."AreaFactor51"))
OR ((s."RA52" is not null and pr."AreaFactor52" is null) OR (s."RA52" is null and pr."AreaFactor52" is not null) OR (s."RA52" != pr."AreaFactor52"))
OR ((s."RA53" is not null and pr."AreaFactor53" is null) OR (s."RA53" is null and pr."AreaFactor53" is not null) OR (s."RA53" != pr."AreaFactor53"))
OR ((s."RA54" is not null and pr."AreaFactor54" is null) OR (s."RA54" is null and pr."AreaFactor54" is not null) OR (s."RA54" != pr."AreaFactor54"))
OR ((s."RA55" is not null and pr."AreaFactor55" is null) OR (s."RA55" is null and pr."AreaFactor55" is not null) OR (s."RA55" != pr."AreaFactor55"))
OR ((s."RA56" is not null and pr."AreaFactor56" is null) OR (s."RA56" is null and pr."AreaFactor56" is not null) OR (s."RA56" != pr."AreaFactor56"))
OR ((s."RA57" is not null and pr."AreaFactor57" is null) OR (s."RA57" is null and pr."AreaFactor57" is not null) OR (s."RA57" != pr."AreaFactor57"))
OR ((s."RA58" is not null and pr."AreaFactor58" is null) OR (s."RA58" is null and pr."AreaFactor58" is not null) OR (s."RA58" != pr."AreaFactor58"))
OR ((s."RA59" is not null and pr."AreaFactor59" is null) OR (s."RA59" is null and pr."AreaFactor59" is not null) OR (s."RA59" != pr."AreaFactor59"))
OR ((s."RA60" is not null and pr."AreaFactor60" is null) OR (s."RA60" is null and pr."AreaFactor60" is not null) OR (s."RA60" != pr."AreaFactor60"))
OR ((s."RA61" is not null and pr."AreaFactor61" is null) OR (s."RA61" is null and pr."AreaFactor61" is not null) OR (s."RA61" != pr."AreaFactor61"))
OR ((s."RA62" is not null and pr."AreaFactor62" is null) OR (s."RA62" is null and pr."AreaFactor62" is not null) OR (s."RA62" != pr."AreaFactor62"))
OR ((s."RA63" is not null and pr."AreaFactor63" is null) OR (s."RA63" is null and pr."AreaFactor63" is not null) OR (s."RA63" != pr."AreaFactor63"))
OR ((s."RA64" is not null and pr."AreaFactor64" is null) OR (s."RA64" is null and pr."AreaFactor64" is not null) OR (s."RA64" != pr."AreaFactor64"))
OR ((s."RA65" is not null and pr."AreaFactor65" is null) OR (s."RA65" is null and pr."AreaFactor65" is not null) OR (s."RA65" != pr."AreaFactor65"))
OR ((s."RA66" is not null and pr."AreaFactor66" is null) OR (s."RA66" is null and pr."AreaFactor66" is not null) OR (s."RA66" != pr."AreaFactor66"))
OR ((s."RA67" is not null and pr."AreaFactor67" is null) OR (s."RA67" is null and pr."AreaFactor67" is not null) OR (s."RA67" != pr."AreaFactor67"))
;

COMMIT;

-- ROLLBACK;

-- Rollback from backup (after commit - IF NEEDED in case something went wrong above)
/*
-- Rollback Plans
UPDATE  public."Plans" p
SET     "UpdatedDate" = current_timestamp
        ,"Carrier" = s."Carrier"
        ,"CarrierFriendlyName" = s."CarrierFriendlyName"
        ,"PlanDisplayName" = s."PlanDisplayName"
        ,"PlanType" = s."PlanType"
        ,"Metal" = s."Metal"
        ,"IsHSA" = s."IsHSA"
        ,"IsActive" = s."IsActive"
        ,"IsForSale" = s."IsForSale"
        ,"ServiceAreaID" = s."ServiceAreaID"
FROM    public."Plans_05092018_BAK" as s
WHERE   s."Year" = p."Year" 
AND     s."HiosPlanID" = p."HiosPlanID"
AND     s."State" = p."State"

-- Rollback Plan Rates
UPDATE   public."PlanRates" pr
SET      "UpdatedDate" = current_timestamp
        ,"BaseRate" = s."BaseRate"
        ,"AreaFactor01" = s."AreaFactor01"
        ,"AreaFactor02" = s."AreaFactor02"
        ,"AreaFactor03" = s."AreaFactor03"
        ,"AreaFactor04" = s."AreaFactor04"
        ,"AreaFactor05" = s."AreaFactor05"
        ,"AreaFactor06" = s."AreaFactor06"
        ,"AreaFactor07" = s."AreaFactor07"
        ,"AreaFactor08" = s."AreaFactor08"
        ,"AreaFactor09" = s."AreaFactor09"
        ,"AreaFactor10" = s."AreaFactor10"
        ,"AreaFactor11" = s."AreaFactor11"
        ,"AreaFactor12" = s."AreaFactor12"
        ,"AreaFactor13" = s."AreaFactor13"
        ,"AreaFactor14" = s."AreaFactor14"
        ,"AreaFactor15" = s."AreaFactor15"
        ,"AreaFactor16" = s."AreaFactor16"
        ,"AreaFactor17" = s."AreaFactor17"
        ,"AreaFactor18" = s."AreaFactor18"
        ,"AreaFactor19" = s."AreaFactor19"
        ,"AreaFactor20" = s."AreaFactor20"
        ,"AreaFactor21" = s."AreaFactor21"
        ,"AreaFactor22" = s."AreaFactor22"
        ,"AreaFactor23" = s."AreaFactor23"
        ,"AreaFactor24" = s."AreaFactor24"
        ,"AreaFactor25" = s."AreaFactor25"
        ,"AreaFactor26" = s."AreaFactor26"
        ,"AreaFactor27" = s."AreaFactor27"
        ,"AreaFactor28" = s."AreaFactor28"
        ,"AreaFactor29" = s."AreaFactor29"
        ,"AreaFactor30" = s."AreaFactor30"
        ,"AreaFactor31" = s."AreaFactor31"
        ,"AreaFactor32" = s."AreaFactor32"
        ,"AreaFactor33" = s."AreaFactor33"
        ,"AreaFactor34" = s."AreaFactor34"
        ,"AreaFactor35" = s."AreaFactor35"
        ,"AreaFactor36" = s."AreaFactor36"
        ,"AreaFactor37" = s."AreaFactor37"
        ,"AreaFactor38" = s."AreaFactor38"
        ,"AreaFactor39" = s."AreaFactor39"
        ,"AreaFactor40" = s."AreaFactor40"
        ,"AreaFactor41" = s."AreaFactor41"
        ,"AreaFactor42" = s."AreaFactor42"
        ,"AreaFactor43" = s."AreaFactor43"
        ,"AreaFactor44" = s."AreaFactor44"
        ,"AreaFactor45" = s."AreaFactor45"
        ,"AreaFactor46" = s."AreaFactor46"
        ,"AreaFactor47" = s."AreaFactor47"
        ,"AreaFactor48" = s."AreaFactor48"
        ,"AreaFactor49" = s."AreaFactor49"
        ,"AreaFactor50" = s."AreaFactor50"
        ,"AreaFactor51" = s."AreaFactor51"
        ,"AreaFactor52" = s."AreaFactor52"
        ,"AreaFactor53" = s."AreaFactor53"
        ,"AreaFactor54" = s."AreaFactor54"
        ,"AreaFactor55" = s."AreaFactor55"
        ,"AreaFactor56" = s."AreaFactor56"
        ,"AreaFactor57" = s."AreaFactor57"
        ,"AreaFactor58" = s."AreaFactor58"
        ,"AreaFactor59" = s."AreaFactor59"
        ,"AreaFactor60" = s."AreaFactor60"
        ,"AreaFactor61" = s."AreaFactor61"
        ,"AreaFactor62" = s."AreaFactor62"
        ,"AreaFactor63" = s."AreaFactor63"
        ,"AreaFactor64" = s."AreaFactor64"
        ,"AreaFactor65" = s."AreaFactor65"
        ,"AreaFactor66" = s."AreaFactor66"
        ,"AreaFactor67" = s."AreaFactor67"
FROM     public."Plans" as p
INNER 
JOIN     public."PlanRates_05092018_BAK" as s   ON  s."Year"       = p."Year" 
                                                AND s."HiosPlanID" = p."HiosPlanID"
WHERE   p."Year"        = pr."Year"
AND     p."HiosPlanID"  = pr."HiosPlanID"

*/

-- Report
SELECT
 p."State" as "State"
,p."Year" as "plan_year"
,cast(null as varchar(30)) as "HIOS Carrier ID"
,p."Carrier" as "Carrier"
,p."CarrierFriendlyName" as "Carrier Marketing Name"
,p."HiosPlanID" as "HIOS Plan ID"
,p."PlanDisplayName" as "plan_name"
,p."PlanType" as "plan_type"
,p."Metal" as "level"
,p."IsHSA" as "HSA"
,p."IsActive" as "is_active"
,p."IsForSale" as "is_for_sale"
,p."ServiceAreaID" as "service_area_id"
,pr."BaseRate" as "BaseRate"
,pr."AreaFactor01" as "RA01"
,pr."AreaFactor02" as "RA02"
,pr."AreaFactor03" as "RA03"
,pr."AreaFactor04" as "RA04"
,pr."AreaFactor05" as "RA05"
,pr."AreaFactor06" as "RA06"
,pr."AreaFactor07" as "RA07"
,pr."AreaFactor08" as "RA08"
,pr."AreaFactor09" as "RA09"
,pr."AreaFactor10" as "RA10"
,pr."AreaFactor11" as "RA11"
,pr."AreaFactor12" as "RA12"
,pr."AreaFactor13" as "RA13"
,pr."AreaFactor14" as "RA14"
,pr."AreaFactor15" as "RA15"
,pr."AreaFactor16" as "RA16"
,pr."AreaFactor17" as "RA17"
,pr."AreaFactor18" as "RA18"
,pr."AreaFactor19" as "RA19"
,pr."AreaFactor20" as "RA20"
,pr."AreaFactor21" as "RA21"
,pr."AreaFactor22" as "RA22"
,pr."AreaFactor23" as "RA23"
,pr."AreaFactor24" as "RA24"
,pr."AreaFactor25" as "RA25"
,pr."AreaFactor26" as "RA26"
,pr."AreaFactor27" as "RA27"
,pr."AreaFactor28" as "RA28"
,pr."AreaFactor29" as "RA29"
,pr."AreaFactor30" as "RA30"
,pr."AreaFactor31" as "RA31"
,pr."AreaFactor32" as "RA32"
,pr."AreaFactor33" as "RA33"
,pr."AreaFactor34" as "RA34"
,pr."AreaFactor35" as "RA35"
,pr."AreaFactor36" as "RA36"
,pr."AreaFactor37" as "RA37"
,pr."AreaFactor38" as "RA38"
,pr."AreaFactor39" as "RA39"
,pr."AreaFactor40" as "RA40"
,pr."AreaFactor41" as "RA41"
,pr."AreaFactor42" as "RA42"
,pr."AreaFactor43" as "RA43"
,pr."AreaFactor44" as "RA44"
,pr."AreaFactor45" as "RA45"
,pr."AreaFactor46" as "RA46"
,pr."AreaFactor47" as "RA47"
,pr."AreaFactor48" as "RA48"
,pr."AreaFactor49" as "RA49"
,pr."AreaFactor50" as "RA50"
,pr."AreaFactor51" as "RA51"
,pr."AreaFactor52" as "RA52"
,pr."AreaFactor53" as "RA53"
,pr."AreaFactor54" as "RA54"
,pr."AreaFactor55" as "RA55"
,pr."AreaFactor56" as "RA56"
,pr."AreaFactor57" as "RA57"
,pr."AreaFactor58" as "RA58"
,pr."AreaFactor59" as "RA59"
,pr."AreaFactor60" as "RA60"
,pr."AreaFactor61" as "RA61"
,pr."AreaFactor62" as "RA62"
,pr."AreaFactor63" as "RA63"
,pr."AreaFactor64" as "RA64"
,pr."AreaFactor65" as "RA65"
,pr."AreaFactor66" as "RA66"
,pr."AreaFactor67" as "RA67"
,CAST(null as VARCHAR(100)) as "Update_date"
,CAST(null as VARCHAR(1000)) as "plan_notes"
FROM    "Plans"  as p
INNER
JOIN    "PlanRates" as pr ON    pr."Year" = p."Year"
                         AND    pr."HiosPlanID" = p."HiosPlanID"
WHERE   EXISTS (SELECT 1 FROM public.stage_planrates_rp502_oh_20180509 as s WHERE s."plan_year" = p."Year" and s."HIOS Plan ID" = p."HiosPlanID" AND s."State" = p."State")
;

