BEGIN;
-- set values to match lookups
UPDATE public.vw_stage_planbenefits pb
SET "CoinsuranceCopayOrder" = 'Copay+Coinsurance'
WHERE "CoinsuranceCopayOrder" = 'CopayCoinsurance';

-- no null for this field, just empty string is the default
UPDATE public.vw_stage_planbenefits pb
SET "CoinsuranceCopayOrder" = ''
WHERE "CoinsuranceCopayOrder" is null;

-- no null for this field, just empty string is the default
UPDATE public.vw_stage_planbenefits pb
SET "CopayAfterFirstVisits" = -1
WHERE "CopayAfterFirstVisits" is null;

-- copay day limit should be -1, never null.
UPDATE public.vw_stage_planbenefits pb
SET "CopayDayLimit" = -1
WHERE "CopayDayLimit" is null;

DELETE FROM vw_stage_planbenefits WHERE "PlanBenefitID" is null and "HiosPlanID" is null;

COMMIT;

-- UPDATE public.vw_stage_planbenefits pb set "CoverageVisitLimit" = -1 WHERE "CoverageVisitLimit" is null;

SELECT *
FROM   public.vw_stage_planbenefits 
WHERE  1 = 0
or "Benefit" is null
or "ServiceNotCovered" is null
or "AppliesToDeductible" is null
--or "AppliesToMOOP" is null
or "Coinsurance" is null
or "CopayAmount" is null
or "CopayDayLimit" is null
or "CoinsuranceCopayOrder" is null
or "MemberServicePaidCap" is null
or "CoverageVisitLimit" is null
or "FirstDollarVisits" is null
or "IsGrouped" is null
or "CopayAfterFirstVisits" is null
;

SELECT COUNT(*) as Row_counts_in_stage FROM public.vw_stage_planbenefits;

-- sanity check do we have all rows?
SELECT  COUNT(*) as RowsInStage_matching_target
FROM    public.vw_stage_planbenefits as stg
INNER 
JOIN    public."PlanBenefits" as pb ON pb."PlanBenefitID" = stg."PlanBenefitID";


--sanity check, any row in our table that match on key but not on HIOSPlanId
SELECT  'HIOSPlanId and/or Year doesnt match' as scomments, count(*) as rwos_HIOSId_Mismatch_count
FROM    public.vw_stage_planbenefits as stg
INNER 
JOIN    public."PlanBenefits" as pb ON pb."PlanBenefitID" = stg."PlanBenefitID"
WHERE   1 = 1
AND     ((stg."Year" != pb."Year") OR (stg."HiosPlanID" != pb."HiosPlanID"))
;


--sanity check, any row in our table that match on Hios Plan but not on PlanBenefitID - DANGER
SELECT  stg."PlanBenefitID", stg."Year", pb."Year", stg."HiosPlanID", pb."HiosPlanID", pb."PlanBenefitID"
FROM    public.vw_stage_planbenefits as stg
INNER 
JOIN    public."PlanBenefits" as pb ON  ((stg."Year" = pb."Year") AND (stg."HiosPlanID" = pb."HiosPlanID") AND stg."Benefit" = pb."Benefit")
WHERE   1 = 1
AND     (pb."PlanBenefitID" != stg."PlanBenefitID")
;

--sanity check, any row in our table that match on key but not on HIOSPlanId
SELECT  stg."PlanBenefitID", stg."Year", pb."Year", stg."HiosPlanID", pb."HiosPlanID", pb."PlanBenefitID"
FROM    public.vw_stage_planbenefits as stg
INNER 
JOIN    public."PlanBenefits" as pb ON pb."PlanBenefitID" = stg."PlanBenefitID"
WHERE   1 = 1
AND     ((stg."Year" != pb."Year") OR (stg."HiosPlanID" != pb."HiosPlanID"))
;

-- Sanity check any rows that are in stage not in prod
SELECT  'rows in stage that are not in target' as scomments, count(*) AS rows_not_in_target
FROM    public.vw_stage_planbenefits as stg
WHERE   NOT EXISTS (SELECT 1  FROM public."PlanBenefits" as pb WHERE pb."PlanBenefitID" = stg."PlanBenefitID");

-- rows that doesn't match at least one of the provided values
-- consider -1 as nulls in stage table.
SELECT   'rows that have at least one mismatching col' as scomments, count(*) as count_of_rows
FROM     public.vw_stage_planbenefits as stg
INNER 
JOIN    public."PlanBenefits" as pb ON   pb."PlanBenefitID" = stg."PlanBenefitID"
                                    AND  stg."Year" = pb."Year"
                                    AND  stg."HiosPlanID" = pb."HiosPlanID"
WHERE    0 = 1
 OR (stg."Benefit" is null AND pb."Benefit" is not null) OR (stg."Benefit" is not null AND pb."Benefit" is null) OR (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" != pb."Benefit")
 OR (stg."ServiceNotCovered" is null AND pb."ServiceNotCovered" is not null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is not null and stg."ServiceNotCovered" != pb."ServiceNotCovered")
 OR (stg."AppliesToDeductible" is null AND pb."AppliesToDeductible" is not null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is not null and stg."AppliesToDeductible" != pb."AppliesToDeductible")
-- OR (stg."AppliesToMOOP" is null AND pb."AppliesToMOOP" is not null) OR (stg."AppliesToMOOP" is not null AND pb."AppliesToMOOP" is null) OR (stg."AppliesToMOOP" is not null AND pb."AppliesToMOOP" is not null and stg."AppliesToMOOP" != pb."AppliesToMOOP")
 OR (stg."Coinsurance" is null AND pb."Coinsurance" is not null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is not null and stg."Coinsurance" != pb."Coinsurance")
 OR (stg."CopayAmount" is null AND pb."CopayAmount" is not null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is not null and stg."CopayAmount" != pb."CopayAmount")
 OR (stg."CopayDayLimit" is null AND pb."CopayDayLimit" is not null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is not null and stg."CopayDayLimit" != pb."CopayDayLimit")
 OR (stg."CoinsuranceCopayOrder" is null AND pb."CoinsuranceCopayOrder" is not null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is not null and stg."CoinsuranceCopayOrder" != pb."CoinsuranceCopayOrder")
 OR (stg."MemberServicePaidCap" is null AND pb."MemberServicePaidCap" is not null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is not null and stg."MemberServicePaidCap" != pb."MemberServicePaidCap")
 OR (stg."CoverageVisitLimit" is null AND pb."CoverageVisitLimit" is not null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is not null and stg."CoverageVisitLimit" != pb."CoverageVisitLimit")
 OR (stg."FirstDollarVisits" is null AND pb."FirstDollarVisits" is not null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is not null and stg."FirstDollarVisits" != pb."FirstDollarVisits")
 OR (stg."IsGrouped" is null AND pb."IsGrouped" is not null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is not null and stg."IsGrouped" != pb."IsGrouped")
 --OR (stg."TieredBenefit" is null AND pb."TieredBenefit" is not null) OR (stg."TieredBenefit" is not null AND pb."TieredBenefit" is null) OR (stg."TieredBenefit" is not null AND pb."TieredBenefit" is not null and stg."TieredBenefit" != pb."TieredBenefit")
 --OR (stg."SeparatedBenefit" is null AND pb."SeparatedBenefit" is not null) OR (stg."SeparatedBenefit" is not null AND pb."SeparatedBenefit" is null) OR (stg."SeparatedBenefit" is not null AND pb."SeparatedBenefit" is not null and stg."SeparatedBenefit" != pb."SeparatedBenefit")
 OR (stg."CopayAfterFirstVisits" is null AND pb."CopayAfterFirstVisits" is not null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is not null and stg."CopayAfterFirstVisits" != pb."CopayAfterFirstVisits")
 --OR (stg."CopayDays" is null AND pb."CopayDays" is not null) OR (stg."CopayDays" is not null AND pb."CopayDays" is null) OR (stg."CopayDays" is not null AND pb."CopayDays" is not null and stg."CopayDays" != pb."CopayDays")
;


 
BEGIN;
 
-- backup
SELECT  *
INTO    public."PlanBenefits_PlanUpdate_03222018_BAK"
FROM    public."PlanBenefits" as pb
WHERE   EXISTS (SELECT 1  FROM public.vw_stage_planbenefits as stg WHERE pb."PlanBenefitID" = stg."PlanBenefitID");

-- count in backup
SELECT count(*) as cnt_in_backup from public."PlanBenefits_PlanUpdate_03222018_BAK";

-- update
UPDATE  public."PlanBenefits" pb
SET     "Benefit" = stg."Benefit"
        , "ServiceNotCovered" = stg."ServiceNotCovered"
        , "AppliesToDeductible" = stg."AppliesToDeductible"
        --, "AppliesToMOOP" = stg."AppliesToMOOP"
        , "Coinsurance" = stg."Coinsurance"
        , "CopayAmount" = stg."CopayAmount"
        , "CopayDayLimit" = stg."CopayDayLimit"
        , "CoinsuranceCopayOrder" = stg."CoinsuranceCopayOrder"
        , "MemberServicePaidCap" = stg."MemberServicePaidCap"
        , "CoverageVisitLimit" = stg."CoverageVisitLimit"
        , "FirstDollarVisits" = stg."FirstDollarVisits"
        , "IsGrouped" = stg."IsGrouped"
        --, "TieredBenefit" = stg."TieredBenefit"
        --, "SeparatedBenefit" = stg."SeparatedBenefit"
        , "CopayAfterFirstVisits" = stg."CopayAfterFirstVisits"
        --, "CopayDays" = stg."CopayDays"
        ,"UpdatedDate" = current_timestamp
FROM    public.vw_stage_planbenefits as stg
WHERE   pb."PlanBenefitID" = stg."PlanBenefitID"
AND     stg."Year" = pb."Year"
AND     stg."HiosPlanID" = pb."HiosPlanID"
AND     (
            0 = 1
         OR (stg."Benefit" is null AND pb."Benefit" is not null) OR (stg."Benefit" is not null AND pb."Benefit" is null) OR (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" != pb."Benefit")
         OR (stg."ServiceNotCovered" is null AND pb."ServiceNotCovered" is not null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is not null and stg."ServiceNotCovered" != pb."ServiceNotCovered")
         OR (stg."AppliesToDeductible" is null AND pb."AppliesToDeductible" is not null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is not null and stg."AppliesToDeductible" != pb."AppliesToDeductible")
         --OR (stg."AppliesToMOOP" is null AND pb."AppliesToMOOP" is not null) OR (stg."AppliesToMOOP" is not null AND pb."AppliesToMOOP" is null) OR (stg."AppliesToMOOP" is not null AND pb."AppliesToMOOP" is not null and stg."AppliesToMOOP" != pb."AppliesToMOOP")
         OR (stg."Coinsurance" is null AND pb."Coinsurance" is not null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is not null and stg."Coinsurance" != pb."Coinsurance")
         OR (stg."CopayAmount" is null AND pb."CopayAmount" is not null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is not null and stg."CopayAmount" != pb."CopayAmount")
         OR (stg."CopayDayLimit" is null AND pb."CopayDayLimit" is not null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is not null and stg."CopayDayLimit" != pb."CopayDayLimit")
         OR (stg."CoinsuranceCopayOrder" is null AND pb."CoinsuranceCopayOrder" is not null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is not null and stg."CoinsuranceCopayOrder" != pb."CoinsuranceCopayOrder")
         OR (stg."MemberServicePaidCap" is null AND pb."MemberServicePaidCap" is not null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is not null and stg."MemberServicePaidCap" != pb."MemberServicePaidCap")
         OR (stg."CoverageVisitLimit" is null AND pb."CoverageVisitLimit" is not null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is not null and stg."CoverageVisitLimit" != pb."CoverageVisitLimit")
         OR (stg."FirstDollarVisits" is null AND pb."FirstDollarVisits" is not null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is not null and stg."FirstDollarVisits" != pb."FirstDollarVisits")
         OR (stg."IsGrouped" is null AND pb."IsGrouped" is not null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is not null and stg."IsGrouped" != pb."IsGrouped")
         --OR (stg."TieredBenefit" is null AND pb."TieredBenefit" is not null) OR (stg."TieredBenefit" is not null AND pb."TieredBenefit" is null) OR (stg."TieredBenefit" is not null AND pb."TieredBenefit" is not null and stg."TieredBenefit" != pb."TieredBenefit")
         --OR (stg."SeparatedBenefit" is null AND pb."SeparatedBenefit" is not null) OR (stg."SeparatedBenefit" is not null AND pb."SeparatedBenefit" is null) OR (stg."SeparatedBenefit" is not null AND pb."SeparatedBenefit" is not null and stg."SeparatedBenefit" != pb."SeparatedBenefit")
         OR (stg."CopayAfterFirstVisits" is null AND pb."CopayAfterFirstVisits" is not null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is not null and stg."CopayAfterFirstVisits" != pb."CopayAfterFirstVisits")
         --OR (stg."CopayDays" is null AND pb."CopayDays" is not null) OR (stg."CopayDays" is not null AND pb."CopayDays" is null) OR (stg."CopayDays" is not null AND pb."CopayDays" is not null and stg."CopayDays" != pb."CopayDays")
         
         );

commit;

--compare after update
SELECT   count(*) as rows_not_updated_count -- should be zero
FROM     public.vw_stage_planbenefits as stg
INNER 
JOIN    public."PlanBenefits" as pb ON   pb."PlanBenefitID" = stg."PlanBenefitID"
                                    AND  stg."Year" = pb."Year"
                                    AND  stg."HiosPlanID" = pb."HiosPlanID"
WHERE    0 = 1
 OR (stg."Benefit" is null AND pb."Benefit" is not null) OR (stg."Benefit" is not null AND pb."Benefit" is null) OR (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" != pb."Benefit")
 OR (stg."ServiceNotCovered" is null AND pb."ServiceNotCovered" is not null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is not null and stg."ServiceNotCovered" != pb."ServiceNotCovered")
 OR (stg."AppliesToDeductible" is null AND pb."AppliesToDeductible" is not null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is not null and stg."AppliesToDeductible" != pb."AppliesToDeductible")
-- OR (stg."AppliesToMOOP" is null AND pb."AppliesToMOOP" is not null) OR (stg."AppliesToMOOP" is not null AND pb."AppliesToMOOP" is null) OR (stg."AppliesToMOOP" is not null AND pb."AppliesToMOOP" is not null and stg."AppliesToMOOP" != pb."AppliesToMOOP")
 OR (stg."Coinsurance" is null AND pb."Coinsurance" is not null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is not null and stg."Coinsurance" != pb."Coinsurance")
 OR (stg."CopayAmount" is null AND pb."CopayAmount" is not null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is not null and stg."CopayAmount" != pb."CopayAmount")
 OR (stg."CopayDayLimit" is null AND pb."CopayDayLimit" is not null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is not null and stg."CopayDayLimit" != pb."CopayDayLimit")
 OR (stg."CoinsuranceCopayOrder" is null AND pb."CoinsuranceCopayOrder" is not null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is not null and stg."CoinsuranceCopayOrder" != pb."CoinsuranceCopayOrder")
 OR (stg."MemberServicePaidCap" is null AND pb."MemberServicePaidCap" is not null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is not null and stg."MemberServicePaidCap" != pb."MemberServicePaidCap")
 OR (stg."CoverageVisitLimit" is null AND pb."CoverageVisitLimit" is not null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is not null and stg."CoverageVisitLimit" != pb."CoverageVisitLimit")
 OR (stg."FirstDollarVisits" is null AND pb."FirstDollarVisits" is not null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is not null and stg."FirstDollarVisits" != pb."FirstDollarVisits")
 OR (stg."IsGrouped" is null AND pb."IsGrouped" is not null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is not null and stg."IsGrouped" != pb."IsGrouped")
 --OR (stg."TieredBenefit" is null AND pb."TieredBenefit" is not null) OR (stg."TieredBenefit" is not null AND pb."TieredBenefit" is null) OR (stg."TieredBenefit" is not null AND pb."TieredBenefit" is not null and stg."TieredBenefit" != pb."TieredBenefit")
 --OR (stg."SeparatedBenefit" is null AND pb."SeparatedBenefit" is not null) OR (stg."SeparatedBenefit" is not null AND pb."SeparatedBenefit" is null) OR (stg."SeparatedBenefit" is not null AND pb."SeparatedBenefit" is not null and stg."SeparatedBenefit" != pb."SeparatedBenefit")
 OR (stg."CopayAfterFirstVisits" is null AND pb."CopayAfterFirstVisits" is not null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is not null and stg."CopayAfterFirstVisits" != pb."CopayAfterFirstVisits")
 --OR (stg."CopayDays" is null AND pb."CopayDays" is not null) OR (stg."CopayDays" is not null AND pb."CopayDays" is null) OR (stg."CopayDays" is not null AND pb."CopayDays" is not null and stg."CopayDays" != pb."CopayDays")
 ;
 
 /*
 
 -- rollback script
 
UPDATE  public."PlanBenefits" pb
SET    "Benefit" = stg."Benefit"
        , "ServiceNotCovered" = stg."ServiceNotCovered"
        , "AppliesToDeductible" = stg."AppliesToDeductible"
        --, "AppliesToMOOP" = stg."AppliesToMOOP"
        , "Coinsurance" = stg."Coinsurance"
        , "CopayAmount" = stg."CopayAmount"
        , "CopayDayLimit" = stg."CopayDayLimit"
        , "CoinsuranceCopayOrder" = stg."CoinsuranceCopayOrder"
        , "MemberServicePaidCap" = stg."MemberServicePaidCap"
        , "CoverageVisitLimit" = stg."CoverageVisitLimit"
        , "FirstDollarVisits" = stg."FirstDollarVisits"
        , "IsGrouped" = stg."IsGrouped"
        --, "TieredBenefit" = stg."TieredBenefit"
        --, "SeparatedBenefit" = stg."SeparatedBenefit"
        , "CopayAfterFirstVisits" = stg."CopayAfterFirstVisits"
        --, "CopayDays" = stg."CopayDays"
        ,"UpdatedDate" = current_timestamp
FROM    public."PlanBenefits_PlanUpdate_03222018_BAK" as stg
WHERE   pb."PlanBenefitID" = stg."PlanBenefitID"
AND     stg."Year" = pb."Year"
AND     stg."HiosPlanID" = pb."HiosPlanID"

*/


-- script to generate comparison statements
/*
SELECT ' OR (stg."' || column_name || '" is null AND pb."' || column_name || '" is not null)'
       || ' OR (stg."' || column_name || '" is not null AND pb."' || column_name || '" is null)'
       || ' OR (stg."' || column_name || '" is not null AND pb."' || column_name || '" is not null and stg."' || column_name || '" != pb."' || column_name || '")'
       as comparescript
        , ', "' || column_name || '" = stg."' || column_name || '"' as update_script
FROM  information_schema.columns
WHERE 1 = 1
AND   table_schema = 'public'
AND   table_name = 'vw_stage_planbenefits'
AND   ordinal_position > 4;
*/

-- Report after update
-- Smaller Report by State
SELECT 
	"PlanBenefitID",
	"PlanBenefits"."Year",
	"PlanBenefits"."HiosPlanID",
	"Plans"."State",
	"Benefit",
	"ServiceNotCovered",
	"AppliesToDeductible",
	"Coinsurance",
	"CopayAmount",
	"CopayDayLimit",
	"CoinsuranceCopayOrder",
	"MemberServicePaidCap",
	"CoverageVisitLimit",
	"FirstDollarVisits",
	"IsGrouped",
	"CopayAfterFirstVisits",
	"Notes",
	"Plans"."GroupID" AS "ClusterID"
FROM "PlanBenefits"
INNER 
JOIN    "Plans" ON "Plans"."HiosPlanID" = "PlanBenefits"."HiosPlanID" AND "Plans"."Year" = "PlanBenefits"."Year"
WHERE   "PlanBenefits"."Year" = 2018 AND "Plans"."IsForSale" = true 
AND     "Benefit"  NOT IN ('MentalHealthProfessionalOutpatient'
                                ,'HabilitationServices','OtherPractitionerOfficeVisit'
                                ,'OutpatientRehabilitationServices','PreventiveCare')
AND     "Plans"."State" = 'HI'
AND     EXISTS (SELECT 1 FROM public.vw_stage_planbenefits as stg 
                WHERE stg."Year" = "Plans"."Year"
                AND   stg."HiosPlanID" = "Plans"."HiosPlanID")
ORDER BY "HiosPlanID", "Benefit";
