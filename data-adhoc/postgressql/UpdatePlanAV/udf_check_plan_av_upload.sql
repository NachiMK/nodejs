-- DROP FUNCTION udf_check_plan_av_upload();
CREATE OR REPLACE FUNCTION udf_check_plan_av_upload() 
        RETURNS void
        LANGUAGE plpgsql
        AS $$
DECLARE
        rcnt INT;
BEGIN
    
        rcnt := 
        (
            SELECT  COUNT(*)
            FROM    public.vw_stage_plan_av_raw 
            WHERE   1 = 0
            OR      "State" IS NULL
            OR      "Year" IS NULL
            OR      "HiosPlanID" IS NULL
            OR      "PlanID" IS NULL
        );
        raise notice 'Rows with Null Values: %', rcnt;

        rcnt := 
        (
            SELECT  COUNT(*) as Row_counts_in_stage
            FROM    public.vw_stage_plan_av_raw
        );
        raise notice 'Row_counts_in_stage: %', rcnt;

        rcnt := 
        (
            SELECT  COUNT(*) as Row_counts_in_stage
            FROM    public.vw_stage_plan_av_raw
            WHERE   LENGTH("PlanID") <= 0
        );
        raise notice 'Plans with invalid Plan ID: %', rcnt;

        -- -- sanity check do we have all rows?
        rcnt := 
        (
            SELECT  COUNT(*) as RowsInStage_matching_ByPlanID
            FROM    public.vw_stage_plan_av_raw as stg
            INNER 
            JOIN    public."Plans" as p ON CAST(p."PlanID" as VARCHAR) = stg."PlanID"
            WHERE   LENGTH(stg."PlanID") > 0
        );
        raise notice 'RowsInStage_matching_ByPlanID: %', rcnt;

        --sanity check, any row in our table that match on key but not on HiosPlanID
        -- RETURN QUERY
        -- SELECT  'HiosPlanID and/or Year doesnt match' as scomments, count(*) as rwos_HIOSId_Mismatch_count
        rcnt :=
        (
            SELECT  COUNT(*)
            FROM    public.vw_stage_plan_av_raw as stg
            INNER 
            JOIN    public."Plans" as p ON CAST(p."PlanID" as VARCHAR) = stg."PlanID"
            WHERE   1 = 1
            AND     ((stg."Year" != p."Year") OR (stg."HiosPlanID" != p."HiosPlanID"))
            AND     LENGTH(stg."PlanID") > 0 -- Just validating only good plans
        );
        raise notice 'Rows_Businesskey_Mismatch_count, Fix these: %', rcnt;

        --sanity check, any row in our table that match on Hios Plan but not on PlanBenefitID - DANGER
        rcnt := 
        (
            SELECT   COUNT(*)
            FROM    public.vw_stage_plan_av_raw as stg
            INNER 
            JOIN    public."Plans" as  p ON  stg."Year"          = p."Year"
                                        AND stg."HiosPlanID"     = p."HiosPlanID"

            WHERE   1 = 1
            AND     CAST(p."PlanID" as VARCHAR) != stg."PlanID"
            AND     LENGTH(stg."PlanID") > 0
        );
        raise notice '***** Plans with incorrect Business keys, Fix these: %', rcnt;

        -- -- Sanity check any rows that are in stage not in prod
        rcnt :=
        (
            SELECT  --'rows in stage that are not in target' as scomments, count(*) AS rows_not_in_target
                    COUNT(*)
            FROM    public.vw_stage_plan_av_raw as stg
            WHERE   NOT EXISTS (SELECT 1  FROM public."Plans" as p 
                                WHERE CAST(p."PlanID" as VARCHAR) = stg."PlanID")
            AND     LENGTH(stg."PlanID") > 0 -- Reason is we send negative numbers for new plan benefits.
        );
        raise notice '**** UNKNOWN Plan(IDs) in Stage Not in PROD, Fix these: %', rcnt;

        -- -- Sanity check any rows that are in stage not in prod
        rcnt :=
        (
            SELECT  --'rows in stage that are not in target' as scomments, count(*) AS rows_not_in_target
                    COUNT(*)
            FROM    public.vw_stage_plan_av_raw as stg
            WHERE   NOT EXISTS (SELECT  1
                                FROM    public."Plans" as p 
                                WHERE   stg."Year"          = p."Year"
                                AND     stg."HiosPlanID"    = p."HiosPlanID"
                                )
            AND     LENGTH(stg."PlanID") <= 0 -- Reason is we send negative numbers for new plan benefits.
        );
        raise notice '***** UNKNOWN Plan IDs, THESE WONT BE INSERTED, FIX THESE: %', rcnt;
        
        -- -- rows that doesn't match at least one of the provided values
        -- -- consider -1 as nulls in stage table.
        rcnt :=
        (
            SELECT   --'rows that have at least one mismatching col' as scomments, count(*) as count_of_rows
                    COUNT(*)
            FROM    public.vw_stage_plan_av_raw as stg
            INNER
            JOIN    public."Plans" as p ON CAST(p."PlanID" as VARCHAR) = stg."PlanID"
            WHERE   LENGTH(stg."PlanID") > 0
            AND     stg."Year" = p."Year"
            AND     stg."HiosPlanID" = p."HiosPlanID"
            AND     (
                        0 = 1
                        OR ((stg."ActuarialValue" != p."ActuarialValue" AND stg."ActuarialValue" IS NOT NULL AND p."ActuarialValue" IS NOT NULL) 
                            OR (stg."ActuarialValue" IS NULL AND p."ActuarialValue" IS NOT NULL) 
                            OR (stg."ActuarialValue" IS NOT NULL AND p."ActuarialValue" IS NULL))
                        OR ((stg."HixmeValuePlus0" != p."HixmeValuePlus0" AND stg."HixmeValuePlus0" IS NOT NULL AND p."HixmeValuePlus0" IS NOT NULL) 
                            OR (stg."HixmeValuePlus0" IS NULL AND p."HixmeValuePlus0" IS NOT NULL) 
                            OR (stg."HixmeValuePlus0" IS NOT NULL AND p."HixmeValuePlus0" IS NULL))
                        OR ((stg."HixmeValuePlus500" != p."HixmeValuePlus500" AND stg."HixmeValuePlus500" IS NOT NULL AND p."HixmeValuePlus500" IS NOT NULL) 
                            OR (stg."HixmeValuePlus500" IS NULL AND p."HixmeValuePlus500" IS NOT NULL) 
                            OR (stg."HixmeValuePlus500" IS NOT NULL AND p."HixmeValuePlus500" IS NULL))
                        OR ((stg."HixmeValuePlus1000" != p."HixmeValuePlus1000" AND stg."HixmeValuePlus1000" IS NOT NULL AND p."HixmeValuePlus1000" IS NOT NULL) 
                            OR (stg."HixmeValuePlus1000" IS NULL AND p."HixmeValuePlus1000" IS NOT NULL) 
                            OR (stg."HixmeValuePlus1000" IS NOT NULL AND p."HixmeValuePlus1000" IS NULL))
                        OR ((stg."HixmeValuePlus1500" != p."HixmeValuePlus1500" AND stg."HixmeValuePlus1500" IS NOT NULL AND p."HixmeValuePlus1500" IS NOT NULL) 
                            OR (stg."HixmeValuePlus1500" IS NULL AND p."HixmeValuePlus1500" IS NOT NULL) 
                            OR (stg."HixmeValuePlus1500" IS NOT NULL AND p."HixmeValuePlus1500" IS NULL))
                        OR ((stg."HixmeValuePlus2000" != p."HixmeValuePlus2000" AND stg."HixmeValuePlus2000" IS NOT NULL AND p."HixmeValuePlus2000" IS NOT NULL) 
                            OR (stg."HixmeValuePlus2000" IS NULL AND p."HixmeValuePlus2000" IS NOT NULL) 
                            OR (stg."HixmeValuePlus2000" IS NOT NULL AND p."HixmeValuePlus2000" IS NULL))
                        OR ((stg."HixmeValuePlus2500" != p."HixmeValuePlus2500" AND stg."HixmeValuePlus2500" IS NOT NULL AND p."HixmeValuePlus2500" IS NOT NULL) 
                            OR (stg."HixmeValuePlus2500" IS NULL AND p."HixmeValuePlus2500" IS NOT NULL) 
                            OR (stg."HixmeValuePlus2500" IS NOT NULL AND p."HixmeValuePlus2500" IS NULL))
                        OR ((CAST(stg."IsApproved" AS BOOLEAN) != p."IsApproved" AND stg."IsApproved" IS NOT NULL AND p."IsApproved" IS NOT NULL) 
                            OR (stg."IsApproved" IS NULL AND p."IsApproved" IS NOT NULL) 
                            OR (stg."IsApproved" IS NOT NULL AND p."IsApproved" IS NULL))
                        /*
                        OR ((stg."IsHSA" != p."IsHSA" AND stg."IsHSA" IS NOT NULL AND p."IsHSA" IS NOT NULL) 
                            OR (stg."IsHSA" IS NULL AND p."IsHSA" IS NOT NULL) 
                            OR (stg."IsHSA" IS NOT NULL AND p."IsHSA" IS NULL))
                        OR ((stg."IsActive" != p."IsActive" AND stg."IsActive" IS NOT NULL AND p."IsActive" IS NOT NULL) 
                            OR (stg."IsActive" IS NULL AND p."IsActive" IS NOT NULL) 
                            OR (stg."IsActive" IS NOT NULL AND p."IsActive" IS NULL))
                        OR ((stg."IsForSale" != p."IsForSale" AND stg."IsForSale" IS NOT NULL AND p."IsForSale" IS NOT NULL) 
                            OR (stg."IsForSale" IS NULL AND p."IsForSale" IS NOT NULL) 
                            OR (stg."IsForSale" IS NOT NULL AND p."IsForSale" IS NULL))
                        OR ((stg."UseForModeling" != p."UseForModeling" AND stg."UseForModeling" IS NOT NULL AND p."UseForModeling" IS NOT NULL) 
                            OR (stg."UseForModeling" IS NULL AND p."UseForModeling" IS NOT NULL) 
                            OR (stg."UseForModeling" IS NOT NULL AND p."UseForModeling" IS NULL))
                        */
                    )
        );
        raise notice 'Rows to Update: %', rcnt;

END;
$$;