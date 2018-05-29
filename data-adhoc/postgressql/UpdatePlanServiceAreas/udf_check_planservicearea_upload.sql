-- DROP FUNCTION udf_check_planservicearea_upload();
CREATE OR REPLACE FUNCTION udf_check_planservicearea_upload() 
        RETURNS void
        LANGUAGE plpgsql
        AS $$
DECLARE
        rcnt INT;
BEGIN
    
        rcnt := 
        (
            SELECT  COUNT(*)
            FROM    public.vw_stage_planserviceareas 
            WHERE   1 = 0
            OR      "IssuerID" IS NULL
            OR      "State" IS NULL
            OR      "Year" IS NULL
            OR      "HiosPlanID" IS NULL
            OR      "ServiceAreaID" IS NULL
            OR      "CoverEntireState" IS NULL
            OR      "PartialCounty" IS NULL
            OR      "IsActive" IS NULL
        );
        raise notice 'Rows with Null Values: %', rcnt;

        rcnt := 
        (
            SELECT  COUNT(*) as Row_counts_in_stage
            FROM    public.vw_stage_planserviceareas
        );
        raise notice 'Row_counts_in_stage: %', rcnt;

        rcnt := 
        (
            SELECT  COUNT(*) as Row_counts_in_stage
            FROM    public.vw_stage_planserviceareas
            WHERE   "PlanServiceAreaID" < 0
        );
        raise notice 'New Benefits to add: %', rcnt;

        -- -- sanity check do we have all rows?
        rcnt := 
        (
            SELECT  COUNT(*) as RowsInStage_matching_target
            FROM    public.vw_stage_planserviceareas as stg
            INNER 
            JOIN    public."PlanServiceAreas" as pb ON pb."PlanServiceAreaID" = stg."PlanServiceAreaID"
            WHERE   stg."PlanServiceAreaID" > 0
        );
        raise notice 'RowsInStage_matching_target: %', rcnt;

        --sanity check, any row in our table that match on key but not on HiosPlanID
        -- RETURN QUERY
        -- SELECT  'HiosPlanID and/or Year doesnt match' as scomments, count(*) as rwos_HIOSId_Mismatch_count
        rcnt :=
        (
            SELECT  COUNT(*)
            FROM    public.vw_stage_planserviceareas as stg
            INNER 
            JOIN    public."PlanServiceAreas" as pb ON pb."PlanServiceAreaID" = stg."PlanServiceAreaID"
            WHERE   1 = 1
            AND     ((stg."Year" != pb."Year") OR (stg."HiosPlanID" != pb."HiosPlanID")
                    OR (stg."IssuerID" != pb."IssuerID") OR (stg."State" != pb."State") OR (stg."ServiceAreaID" != pb."ServiceAreaID"))
            AND     stg."PlanServiceAreaID" > 0 -- Reason is we send negative numbers for new plan benefits.
        );
        raise notice 'Rows_Businesskey_Mismatch_count, Fix these: %', rcnt;

        --sanity check, any row in our table that match on Hios Plan but not on PlanBenefitID - DANGER
        rcnt := 
        (
            SELECT   COUNT(*)
                    --  stg."PlanBenefitID"
                    -- ,stg."Year"
                    -- ,pb."Year"
                    -- ,stg."HiosPlanID"
                    -- ,pb."HiosPlanID"
                    -- ,pb."PlanBenefitID"
            FROM    public.vw_stage_planserviceareas as stg
            INNER 
            JOIN    public."PlanServiceAreas" as pb ON  stg."Year"           = pb."Year"
                                                    AND stg."HiosPlanID"     = pb."HiosPlanID"
                                                    AND stg."State"          = pb."State"
                                                    AND  pb."IssuerID"       = stg."IssuerID"
                                                    AND  pb."ServiceAreaID"  = stg."ServiceAreaID"
                                                    AND  COALESCE(pb."CountyCode", '0')   = COALESCE(stg."CountyCode", '0')
                                                    AND  COALESCE(pb."Zipcode", '0') = COALESCE(stg."Zipcode", '0')
            WHERE   1 = 1
            AND     pb."PlanServiceAreaID" != stg."PlanServiceAreaID"
            AND     stg."PlanServiceAreaID" > 0
        );
        raise notice 'PlanServiceArea with incorrect Business keys, Fix these: %', rcnt;

        -- -- Sanity check any rows that are in stage not in prod
        rcnt :=
        (
            SELECT  --'rows in stage that are not in target' as scomments, count(*) AS rows_not_in_target
                    COUNT(*)
            FROM    public.vw_stage_planserviceareas as stg
            WHERE   NOT EXISTS (SELECT 1  FROM public."PlanServiceAreas" as pb 
                                WHERE pb."PlanServiceAreaID" = stg."PlanServiceAreaID")
            AND     stg."PlanServiceAreaID" > 0 -- Reason is we send negative numbers for new plan benefits.
        );
        raise notice 'Non Negative Plan-Benefit(IDs) in Stage Not in PROD, Fix these: %', rcnt;

        -- -- Sanity check any rows that are in stage not in prod
        rcnt :=
        (
            SELECT  --'rows in stage that are not in target' as scomments, count(*) AS rows_not_in_target
                    COUNT(*)
            FROM    public.vw_stage_planserviceareas as stg
            WHERE   NOT EXISTS (SELECT  1
                                FROM    public."PlanServiceAreas" as pb 
                                WHERE   stg."Year"          = pb."Year"
                                AND     stg."HiosPlanID"    = pb."HiosPlanID"
                                AND     stg."State"         = pb."State"
                                AND     pb."IssuerID"       = stg."IssuerID"
                                AND     pb."ServiceAreaID"  = stg."ServiceAreaID"
                                AND     COALESCE(pb."CountyCode", '0')   = COALESCE(stg."CountyCode", '0')
                                AND     COALESCE(pb."Zipcode", '0') = COALESCE(stg."Zipcode", '0'))
            AND     stg."PlanServiceAreaID" < 0 -- Reason is we send negative numbers for new plan benefits.
        );
        raise notice 'New Benefits, Insert These: %', rcnt;
        
        -- -- rows that doesn't match at least one of the provided values
        -- -- consider -1 as nulls in stage table.
        rcnt :=
        (
            SELECT   --'rows that have at least one mismatching col' as scomments, count(*) as count_of_rows
                    COUNT(*)
            FROM    public.vw_stage_planserviceareas as stg
            INNER
            JOIN    public."PlanServiceAreas" as psa ON psa."PlanServiceAreaID" = stg."PlanServiceAreaID"
            WHERE   stg."PlanServiceAreaID" > 0
            AND     stg."Year" = psa."Year"
            AND     (
                        0 = 1
                    --    ((stg."State" != psa."State" AND stg."State" IS NOT NULL AND psa."State" IS NOT NULL) OR (stg."State" IS NULL AND psa."State" IS NOT NULL) OR (stg."State" IS NOT NULL AND psa."State" IS NULL))
                    -- OR ((stg."IssuerID" != psa."IssuerID" AND stg."IssuerID" IS NOT NULL AND psa."IssuerID" IS NOT NULL) OR (stg."IssuerID" IS NULL AND psa."IssuerID" IS NOT NULL) OR (stg."IssuerID" IS NOT NULL AND psa."IssuerID" IS NULL))
                    -- OR ((stg."SourceName" != psa."SourceName" AND stg."SourceName" IS NOT NULL AND psa."SourceName" IS NOT NULL) OR (stg."SourceName" IS NULL AND psa."SourceName" IS NOT NULL) OR (stg."SourceName" IS NOT NULL AND psa."SourceName" IS NULL))
                    -- OR ((stg."HiosPlanID" != psa."HiosPlanID" AND stg."HiosPlanID" IS NOT NULL AND psa."HiosPlanID" IS NOT NULL) OR (stg."HiosPlanID" IS NULL AND psa."HiosPlanID" IS NOT NULL) OR (stg."HiosPlanID" IS NOT NULL AND psa."HiosPlanID" IS NULL))
                    -- OR ((stg."ServiceAreaID" != psa."ServiceAreaID" AND stg."ServiceAreaID" IS NOT NULL AND psa."ServiceAreaID" IS NOT NULL) OR (stg."ServiceAreaID" IS NULL AND psa."ServiceAreaID" IS NOT NULL) OR (stg."ServiceAreaID" IS NOT NULL AND psa."ServiceAreaID" IS NULL))
                    OR ((stg."ServiceAreaName" <> psa."ServiceAreaName" AND stg."ServiceAreaName" IS NOT NULL AND psa."ServiceAreaName" IS NOT NULL) OR (stg."ServiceAreaName" IS NULL AND psa."ServiceAreaName" IS NOT NULL) OR (stg."ServiceAreaName" IS NOT NULL AND psa."ServiceAreaName" IS NULL))
                    OR ((CAST(stg."CoverEntireState" as boolean) != psa."CoverEntireState" AND stg."CoverEntireState" IS NOT NULL AND psa."CoverEntireState" IS NOT NULL) OR (stg."CoverEntireState" IS NULL AND psa."CoverEntireState" IS NOT NULL) OR (stg."CoverEntireState" IS NOT NULL AND psa."CoverEntireState" IS NULL))
                    --OR ((stg."CountyCode" != psa."CountyCode" AND stg."CountyCode" IS NOT NULL AND psa."CountyCode" IS NOT NULL) OR (stg."CountyCode" IS NULL AND psa."CountyCode" IS NOT NULL) OR (stg."CountyCode" IS NOT NULL AND psa."CountyCode" IS NULL))
                    OR ((CAST(stg."PartialCounty" as boolean) != psa."PartialCounty" AND stg."PartialCounty" IS NOT NULL AND psa."PartialCounty" IS NOT NULL) OR (stg."PartialCounty" IS NULL AND psa."PartialCounty" IS NOT NULL) OR (stg."PartialCounty" IS NOT NULL AND psa."PartialCounty" IS NULL))
                    --OR ((stg."Zipcode" != psa."Zipcode" AND stg."Zipcode" IS NOT NULL AND psa."Zipcode" IS NOT NULL) OR (stg."Zipcode" IS NULL AND psa."Zipcode" IS NOT NULL) OR (stg."Zipcode" IS NOT NULL AND psa."Zipcode" IS NULL))
                    OR ((CAST(stg."IsActive" as boolean) != psa."IsActive" AND stg."IsActive" IS NOT NULL AND psa."IsActive" IS NOT NULL) OR (stg."IsActive" IS NULL AND psa."IsActive" IS NOT NULL) OR (stg."IsActive" IS NOT NULL AND psa."IsActive" IS NULL))
                    )
        );
        raise notice 'Rows to Update: %', rcnt;

END;
$$;