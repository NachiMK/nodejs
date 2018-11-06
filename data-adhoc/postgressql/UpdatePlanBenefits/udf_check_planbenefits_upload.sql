-- DROP FUNCTION udf_check_planbenefits_upload();
CREATE OR REPLACE FUNCTION udf_check_planbenefits_upload() 
        RETURNS void
        LANGUAGE plpgsql
        AS $$
DECLARE
        rcnt INT;
BEGIN
    
        rcnt := 
        (
            SELECT  COUNT(*)
            FROM    public.vw_stage_planbenefits 
            WHERE   1 = 0
            OR      "Benefit" IS NULL
            OR      "ServiceNotCovered" IS NULL
            OR      "AppliesToDeductible" IS NULL
            OR      "Coinsurance" IS NULL
            OR      "CopayAmount" IS NULL
            OR      "CopayDayLimit" IS NULL
            OR      "CoinsuranceCopayOrder" IS NULL
            OR      "MemberServicePaidCap" IS NULL
            OR      "CoverageVisitLimit" IS NULL
            OR      "FirstDollarVisits" IS NULL
            OR      "IsGrouped" IS NULL
            OR      "CopayAfterFirstVisits" IS NULL
        );
        raise notice 'Rows with Null Values: %', rcnt;

        rcnt := 
        (
            SELECT  COUNT(*) as Row_counts_in_stage
            FROM    public.vw_stage_planbenefits
        );
        raise notice 'Row_counts_in_stage: %', rcnt;

        rcnt := 
        (
            SELECT  COUNT(*) as Row_counts_in_stage
            FROM    public.vw_stage_planbenefits
            WHERE   "PlanBenefitID" < 0
        );
        raise notice 'New Benefits to add: %', rcnt;

        -- -- sanity check do we have all rows?
        rcnt := 
        (
            SELECT  COUNT(*) as RowsInStage_matching_target
            FROM    public.vw_stage_planbenefits as stg
            INNER 
            JOIN    public."PlanBenefits" as pb ON pb."PlanBenefitID" = stg."PlanBenefitID"
            WHERE   stg."PlanBenefitID" > 0
        );
        raise notice 'RowsInStage_matching_target: %', rcnt;

        --sanity check, any row in our table that match on key but not on HIOSPlanId
        -- RETURN QUERY
        -- SELECT  'HIOSPlanId and/or Year doesnt match' as scomments, count(*) as rwos_HIOSId_Mismatch_count
        rcnt :=
        (
            SELECT  COUNT(*)
            FROM    public.vw_stage_planbenefits as stg
            INNER 
            JOIN    public."PlanBenefits" as pb ON pb."PlanBenefitID" = stg."PlanBenefitID"
            WHERE   1 = 1
            AND     ((stg."Year" != pb."Year") OR (stg."HiosPlanID" != pb."HiosPlanID"))
            AND     stg."PlanBenefitID" > 0 -- Reason is we send negative numbers for new plan benefits.
        );
        raise notice 'Rows_HIOSId_Mismatch_count, Fix these: %', rcnt;

        --sanity check, any row in our table that match on Hios Plan but not on PlanBenefitID - DANGER
        rcnt := 
        (
            SELECT   COUNT(*)
            FROM    public.vw_stage_planbenefits as stg
            INNER 
            JOIN    public."PlanBenefits" as pb ON  stg."Year"          = pb."Year"
                                                AND stg."HiosPlanID"    = pb."HiosPlanID"
                                                AND stg."Benefit"       = pb."Benefit"
            WHERE   1 = 1
            AND     pb."PlanBenefitID" != stg."PlanBenefitID"
            AND     stg."PlanBenefitID" > 0
        );
        raise notice 'PlanBenefit with incorrect PlanBenefitIDs, Fix these: %', rcnt;

        -- --sanity check, any row in our table that match on key but not on HIOSPlanId
        -- RETURN QUERY
        -- SELECT  stg."PlanBenefitID", stg."Year", pb."Year", stg."HiosPlanID", pb."HiosPlanID", pb."PlanBenefitID"
        rcnt :=
        (
            SELECT COUNT(*)
            FROM    public.vw_stage_planbenefits as stg
            INNER 
            JOIN    public."PlanBenefits" as pb ON pb."PlanBenefitID" = stg."PlanBenefitID"
            WHERE   1 = 1
            AND     ((stg."Year" != pb."Year") OR (stg."HiosPlanID" != pb."HiosPlanID"))
        );
        raise notice 'Mismatch HiosPlanId for PlanBenefits, Fix these: %', rcnt;

        -- -- Sanity check any rows that are in stage not in prod
        rcnt :=
        (
            SELECT  --'rows in stage that are not in target' as scomments, count(*) AS rows_not_in_target
                    COUNT(*)
            FROM    public.vw_stage_planbenefits as stg
            WHERE   NOT EXISTS (SELECT 1  FROM public."PlanBenefits" as pb 
                                WHERE pb."PlanBenefitID" = stg."PlanBenefitID")
            AND     stg."PlanBenefitID" > 0 -- Reason is we send negative numbers for new plan benefits.
        );
        raise notice 'Non Negative Plan-Benefit(IDs) in Stage Not in PROD, Fix these: %', rcnt;

        -- -- Sanity check any rows that are in stage not in prod
        rcnt :=
        (
            SELECT  --'rows in stage that are not in target' as scomments, count(*) AS rows_not_in_target
                    COUNT(*)
            FROM    public.vw_stage_planbenefits as stg
            WHERE   NOT EXISTS (SELECT  1
                                FROM    public."PlanBenefits" as pb 
                                WHERE   stg."Year"          = pb."Year"
                                AND     stg."HiosPlanID"    = pb."HiosPlanID"
                                AND     stg."Benefit"       = pb."Benefit")
            AND     stg."PlanBenefitID" < 0 -- Reason is we send negative numbers for new plan benefits.
        );
        raise notice 'New Benefits, Insert These: %', rcnt;
        
        -- -- rows that doesn't match at least one of the provided values
        -- -- consider -1 as nulls in stage table.
        rcnt :=
        (
            SELECT   --'rows that have at least one mismatching col' as scomments, count(*) as count_of_rows
                    COUNT(*)
            FROM     public.vw_stage_planbenefits as stg
            INNER 
            JOIN    public."PlanBenefits" as pb ON   pb."PlanBenefitID" = stg."PlanBenefitID"
                                                AND  stg."Year" = pb."Year"
                                                AND  stg."HiosPlanID" = pb."HiosPlanID"
                                                AND  stg."PlanBenefitID" > 0
            WHERE    0 = 1
            OR (stg."Benefit" IS NULL AND pb."Benefit" is not null) OR (stg."Benefit" is not null AND pb."Benefit" IS NULL) OR (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" != pb."Benefit")
            OR (stg."ServiceNotCovered" IS NULL AND pb."ServiceNotCovered" is not null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" IS NULL) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is not null and stg."ServiceNotCovered" != pb."ServiceNotCovered")
            OR (stg."AppliesToDeductible" IS NULL AND pb."AppliesToDeductible" is not null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" IS NULL) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is not null and stg."AppliesToDeductible" != pb."AppliesToDeductible")
            OR (stg."Coinsurance" IS NULL AND pb."Coinsurance" is not null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" IS NULL) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is not null and stg."Coinsurance" != pb."Coinsurance")
            OR (stg."CopayAmount" IS NULL AND pb."CopayAmount" is not null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" IS NULL) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is not null and stg."CopayAmount" != pb."CopayAmount")
            OR (stg."CopayDayLimit" IS NULL AND pb."CopayDayLimit" is not null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" IS NULL) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is not null and stg."CopayDayLimit" != pb."CopayDayLimit")
            OR (stg."CoinsuranceCopayOrder" IS NULL AND pb."CoinsuranceCopayOrder" is not null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" IS NULL) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is not null and stg."CoinsuranceCopayOrder" != pb."CoinsuranceCopayOrder")
            OR (stg."MemberServicePaidCap" IS NULL AND pb."MemberServicePaidCap" is not null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" IS NULL) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is not null and stg."MemberServicePaidCap" != pb."MemberServicePaidCap")
            OR (stg."CoverageVisitLimit" IS NULL AND pb."CoverageVisitLimit" is not null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" IS NULL) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is not null and stg."CoverageVisitLimit" != pb."CoverageVisitLimit")
            OR (stg."FirstDollarVisits" IS NULL AND pb."FirstDollarVisits" is not null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" IS NULL) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is not null and stg."FirstDollarVisits" != pb."FirstDollarVisits")
            OR (stg."IsGrouped" IS NULL AND pb."IsGrouped" is not null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" IS NULL) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is not null and stg."IsGrouped" != pb."IsGrouped")
            OR (stg."CopayAfterFirstVisits" IS NULL AND pb."CopayAfterFirstVisits" is not null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" IS NULL) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is not null and stg."CopayAfterFirstVisits" != pb."CopayAfterFirstVisits")
        );
        raise notice 'Existing Rows (by PlanBenefitID) to Update: %', rcnt;

        -- -- rows that doesn't match at least one of the provided values
        -- -- consider -1 as nulls in stage table.
        rcnt :=
        (
            SELECT   --'rows that have at least one mismatching col' as scomments, count(*) as count_of_rows
                    COUNT(*)
            FROM     public.vw_stage_planbenefits as stg
            INNER 
            JOIN    public."PlanBenefits" as pb ON   pb."Benefit" = stg."Benefit"
                                                AND  stg."PlanBenefitID" < 0
                                                AND  stg."Year" = pb."Year"
                                                AND  stg."HiosPlanID" = pb."HiosPlanID"
            WHERE    0 = 1
            OR (stg."Benefit" IS NULL AND pb."Benefit" is not null) OR (stg."Benefit" is not null AND pb."Benefit" IS NULL) OR (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" != pb."Benefit")
            OR (stg."ServiceNotCovered" IS NULL AND pb."ServiceNotCovered" is not null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" IS NULL) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is not null and stg."ServiceNotCovered" != pb."ServiceNotCovered")
            OR (stg."AppliesToDeductible" IS NULL AND pb."AppliesToDeductible" is not null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" IS NULL) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is not null and stg."AppliesToDeductible" != pb."AppliesToDeductible")
            OR (stg."Coinsurance" IS NULL AND pb."Coinsurance" is not null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" IS NULL) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is not null and stg."Coinsurance" != pb."Coinsurance")
            OR (stg."CopayAmount" IS NULL AND pb."CopayAmount" is not null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" IS NULL) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is not null and stg."CopayAmount" != pb."CopayAmount")
            OR (stg."CopayDayLimit" IS NULL AND pb."CopayDayLimit" is not null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" IS NULL) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is not null and stg."CopayDayLimit" != pb."CopayDayLimit")
            OR (stg."CoinsuranceCopayOrder" IS NULL AND pb."CoinsuranceCopayOrder" is not null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" IS NULL) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is not null and stg."CoinsuranceCopayOrder" != pb."CoinsuranceCopayOrder")
            OR (stg."MemberServicePaidCap" IS NULL AND pb."MemberServicePaidCap" is not null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" IS NULL) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is not null and stg."MemberServicePaidCap" != pb."MemberServicePaidCap")
            OR (stg."CoverageVisitLimit" IS NULL AND pb."CoverageVisitLimit" is not null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" IS NULL) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is not null and stg."CoverageVisitLimit" != pb."CoverageVisitLimit")
            OR (stg."FirstDollarVisits" IS NULL AND pb."FirstDollarVisits" is not null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" IS NULL) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is not null and stg."FirstDollarVisits" != pb."FirstDollarVisits")
            OR (stg."IsGrouped" IS NULL AND pb."IsGrouped" is not null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" IS NULL) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is not null and stg."IsGrouped" != pb."IsGrouped")
            OR (stg."CopayAfterFirstVisits" IS NULL AND pb."CopayAfterFirstVisits" is not null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" IS NULL) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is not null and stg."CopayAfterFirstVisits" != pb."CopayAfterFirstVisits")
        );
        raise notice 'Existing Rows (by Benefit) to Update: %', rcnt;

END;
$$;