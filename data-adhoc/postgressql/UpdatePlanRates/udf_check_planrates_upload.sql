-- DROP FUNCTION udf_check_planrates_upload();
CREATE OR REPLACE FUNCTION udf_check_planrates_upload() 
        RETURNS void
        LANGUAGE plpgsql
        AS $$
DECLARE
        rcnt INT;
BEGIN
    
        rcnt := 
        (
            SELECT  COUNT(*)
            FROM    public.vw_stage_planrates_raw 
            WHERE   1 = 0
            OR      "State" IS NULL
            OR      "plan_year" IS NULL
            OR      "Hios Plan ID" IS NULL
            OR      "BaseRate" IS NULL
        );
        raise notice 'Rows with Null Values: %', rcnt;

        rcnt := 
        (
            SELECT  COUNT(*) as Row_counts_in_stage
            FROM    public.vw_stage_planrates_raw
        );
        raise notice 'Row_counts_in_stage: %', rcnt;

        rcnt := 
        (
            SELECT  COUNT(*) as Row_counts_in_stage
            FROM    public.vw_stage_planrates_raw
            WHERE   LENGTH("Hios Plan ID") <= 0
        );
        raise notice 'Plans with invalid HIOS Plan ID: %', rcnt;

        -- -- sanity check do we have all rows?
        rcnt := 
        (
            SELECT  COUNT(*)
            FROM    public.vw_stage_planrates_raw as stg
            INNER 
            JOIN    public."Plans" as  p ON stg."plan_year"      = p."Year"
                                        AND stg."Hios Plan ID"   = p."HiosPlanID"
                                        AND stg."State"          = p."State"

            WHERE   1 = 1

        );
        raise notice 'RowsInStage_matching_ByHiosPlanID: %', rcnt;
        
        -- -- sanity check do we have all rows in Plan Rates?
        rcnt := 
        (
            SELECT   COUNT(*) as "MissingPlanRatesCount" -- If more than zero stop updates
            FROM     public.vw_stage_planrates_raw as s
            WHERE    NOT EXISTS (SELECT 1 FROM "PlanRates" as pr WHERE s."plan_year" = pr."Year" and s."Hios Plan ID" = pr."HiosPlanID")
        );
        raise notice '# of Plans not in PlanRates, these will be INSERTED: %', rcnt;

        -- -- Sanity check any rows that are in stage not in prod
        rcnt :=
        (
            SELECT  --'rows in stage that are not in target' as scomments, count(*) AS rows_not_in_target
                    COUNT(*)
            FROM    public.vw_stage_planrates_raw as stg
            WHERE   NOT EXISTS (SELECT 1  FROM public."Plans" as p 
                                WHERE   CAST(p."HiosPlanID" as VARCHAR) = stg."Hios Plan ID"
                                AND     p."State" = stg."State"
                                AND     p."Year"  = stg."plan_year")
        );
        raise notice '**** UNKNOWN Plan(IDs) in Stage Not in PROD, These will be added: %', rcnt;

        
        -- -- rows that doesn't match at least one of the provided values
        rcnt :=
        (
            SELECT   COUNT(*) -- If zero then no need to update Plans
            FROM     public.vw_stage_planrates_raw as s
            INNER 
            JOIN     public."Plans" as p ON  s."plan_year" = p."Year" 
                                        AND s."Hios Plan ID" = p."HiosPlanID"
                                        AND s."State" = p."State"
            WHERE    1 = 0
            OR ((s."Carrier" is not null and p."Carrier" is null) OR (s."Carrier" is null and p."Carrier" is not null) OR (s."Carrier" != p."Carrier"))
            OR ((s."Carrier Marketing Name" is not null and p."CarrierFriendlyName" is null) OR (s."Carrier Marketing Name" is null and p."CarrierFriendlyName" is not null) OR (s."Carrier Marketing Name" != p."CarrierFriendlyName"))
            OR ((s."Plan Marketing Name" is not null and p."PlanMarketingName" is null) OR (s."Plan Marketing Name" is null and p."PlanMarketingName" is not null) OR (s."Plan Marketing Name" != p."PlanMarketingName"))
            OR ((s."plan_type" is not null and p."PlanType" is null) OR (s."plan_type" is null and p."PlanType" is not null) OR (s."plan_type" != p."PlanType"))
            OR ((s."level" is not null and p."Metal" is null) OR (s."level" is null and p."Metal" is not null) OR (s."level" != p."Metal"))
            OR ((s."HSA" is not null and p."IsHSA" is null) OR (s."HSA" is null and p."IsHSA" is not null) OR (s."HSA" != CAST(p."IsHSA" as VARCHAR(20))))
            OR ((s."is_active" is not null and p."IsActive" is null) OR (s."is_active" is null and p."IsActive" is not null) OR (s."is_active" != CAST(p."IsActive" as VARCHAR(20))))
            OR ((s."is_for_sale" is not null and p."IsForSale" is null) OR (s."is_for_sale" is null and p."IsForSale" is not null) OR (s."is_for_sale" != CAST(p."IsForSale" as VARCHAR(20))))
            OR ((s."use_for_modeling" is not null and p."UseForModeling" is null) OR (s."use_for_modeling" is null and p."UseForModeling" is not null) OR (s."use_for_modeling" != CAST(p."UseForModeling" as VARCHAR(20))))
            OR ((s."service_area_id" is not null and p."ServiceAreaID" is null) OR (s."service_area_id" is null and p."ServiceAreaID" is not null) OR (s."service_area_id" != p."ServiceAreaID"))
        );
        raise notice 'Rows to Update Plans Table: %', rcnt;

        -- -- rows that doesn't match at least one of the provided values
        rcnt :=
        (
            SELECT   COUNT(*) -- If zero then no need to update Plans
            FROM     public.vw_stage_planrates_raw as s
            INNER 
            JOIN     public."Plans" as p ON  s."plan_year" = p."Year" 
                                        AND s."Hios Plan ID" = p."HiosPlanID"
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
        );
        raise notice 'Rows to Update PlanRates table: %', rcnt;

END;
$$;