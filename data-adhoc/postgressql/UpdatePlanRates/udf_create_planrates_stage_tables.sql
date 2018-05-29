-- DROP FUNCTION udf_create_planrates_stage_tables(varchar(255));
CREATE OR REPLACE FUNCTION udf_create_planrates_stage_tables(table_name VARCHAR(255)) RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
        sql_code VARCHAR;
        full_table_name VARCHAR;
BEGIN

    full_table_name := (SELECT 'public.stage_planrates_raw_' 
                        || coalesce(table_name, '') 
                        || '_' 
                        || to_char(current_timestamp, 'YYYYMMDD'));
    
    EXECUTE 'DROP VIEW IF EXISTS public.vw_plansrates_updates;';
    EXECUTE 'DROP VIEW IF EXISTS public.vw_stage_planrates_raw;';
	EXECUTE 'DROP TABLE IF EXISTS ' || full_table_name || ';';
	
    sql_code := 'CREATE TABLE IF NOT EXISTS ' || full_table_name || ' AS 
    SELECT
     p."State" as "State"
    ,p."Year" as "plan_year"
    ,cast(null as varchar(30)) as "HIOS Carrier ID"
    ,p."Carrier" as "Carrier"
    ,p."PlanMarketingName" as "Carrier Marketing Name"
    ,p."HiosPlanID" as "Hios Plan ID"
    ,p."PlanMarketingName" as "Plan Marketing Name"
    ,p."PlanType" as "plan_type"
    ,p."Metal" as "level"
    ,CAST(p."IsHSA" as VARCHAR(10)) as "HSA"
    ,CAST(p."UseForModeling" as VARCHAR(10)) as "use_for_modeling" 
    ,CAST(p."IsActive" as VARCHAR(10)) as "is_active"
    ,CAST(p."IsForSale" as VARCHAR(10)) as "is_for_sale"
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
    FROM    public."Plans"  as p
    INNER
    JOIN    public."PlanRates" as pr ON     pr."Year" = p."Year"
                                    AND    pr."HiosPlanID" = p."HiosPlanID"
    WHERE 1 = 0;';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE TABLE IF NOT EXISTS public.stage_planrates_clean
        (
          "PlanRates_StageID"     SERIAL          NOT NULL
        , "State" CHARACTER VARYING(6) NOT NULL
        , "Year" SMALLINT NOT NULL
        , "HIOSCarrierID" CHARACTER VARYING(30)
        , "Carrier" CHARACTER VARYING(240)
        , "CarrierFriendlyName" CHARACTER VARYING(300)
        , "HiosPlanID" CHARACTER VARYING(45) NOT NULL
        , "PlanMarketingName" CHARACTER VARYING(300)
        , "PlanType" CHARACTER VARYING(15)
        , "Metal" CHARACTER VARYING(36)
        , "IsHSA" BOOLEAN
        , "UseForModeling" BOOLEAN
        , "IsActive" BOOLEAN
        , "IsForSale" BOOLEAN
        , "ServiceAreaID" CHARACTER VARYING(75)
        , "BaseRate" NUMERIC(12,8)
        , "RA01" NUMERIC(12,8)
        , "RA02" NUMERIC(12,8)
        , "RA03" NUMERIC(12,8)
        , "RA04" NUMERIC(12,8)
        , "RA05" NUMERIC(12,8)
        , "RA06" NUMERIC(12,8)
        , "RA07" NUMERIC(12,8)
        , "RA08" NUMERIC(12,8)
        , "RA09" NUMERIC(12,8)
        , "RA10" NUMERIC(12,8)
        , "RA11" NUMERIC(12,8)
        , "RA12" NUMERIC(12,8)
        , "RA13" NUMERIC(12,8)
        , "RA14" NUMERIC(12,8)
        , "RA15" NUMERIC(12,8)
        , "RA16" NUMERIC(12,8)
        , "RA17" NUMERIC(12,8)
        , "RA18" NUMERIC(12,8)
        , "RA19" NUMERIC(12,8)
        , "RA20" NUMERIC(12,8)
        , "RA21" NUMERIC(12,8)
        , "RA22" NUMERIC(12,8)
        , "RA23" NUMERIC(12,8)
        , "RA24" NUMERIC(12,8)
        , "RA25" NUMERIC(12,8)
        , "RA26" NUMERIC(12,8)
        , "RA27" NUMERIC(12,8)
        , "RA28" NUMERIC(12,8)
        , "RA29" NUMERIC(12,8)
        , "RA30" NUMERIC(12,8)

        , "RA31" NUMERIC(12,8)
        , "RA32" NUMERIC(12,8)
        , "RA33" NUMERIC(12,8)
        , "RA34" NUMERIC(12,8)
        , "RA35" NUMERIC(12,8)
        , "RA36" NUMERIC(12,8)
        , "RA37" NUMERIC(12,8)
        , "RA38" NUMERIC(12,8)
        , "RA39" NUMERIC(12,8)
        , "RA40" NUMERIC(12,8)

        , "RA41" NUMERIC(12,8)
        , "RA42" NUMERIC(12,8)
        , "RA43" NUMERIC(12,8)
        , "RA44" NUMERIC(12,8)
        , "RA45" NUMERIC(12,8)
        , "RA46" NUMERIC(12,8)
        , "RA47" NUMERIC(12,8)
        , "RA48" NUMERIC(12,8)
        , "RA49" NUMERIC(12,8)
        , "RA50" NUMERIC(12,8)

        , "RA51" NUMERIC(12,8)
        , "RA52" NUMERIC(12,8)
        , "RA53" NUMERIC(12,8)
        , "RA54" NUMERIC(12,8)
        , "RA55" NUMERIC(12,8)
        , "RA56" NUMERIC(12,8)
        , "RA57" NUMERIC(12,8)
        , "RA58" NUMERIC(12,8)
        , "RA59" NUMERIC(12,8)
        , "RA60" NUMERIC(12,8)

        , "RA61" NUMERIC(12,8)
        , "RA62" NUMERIC(12,8)
        , "RA63" NUMERIC(12,8)
        , "RA64" NUMERIC(12,8)
        , "RA65" NUMERIC(12,8)
        , "RA66" NUMERIC(12,8)
        , "RA67" NUMERIC(12,8)
      
        , "CreatedDate"          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
        , "StageTableName"       VARCHAR(200)    NOT NULL
      );';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE UNIQUE INDEX IF NOT EXISTS UNQ_stage_planrates_clean
                    ON stage_planrates_clean("StageTableName", "HiosPlanID", "Year", "State");';
    execute sql_code;

    sql_code := 'CREATE INDEX IF NOT EXISTS IDX_stage_planrates_clean_HIOS_Year
                    ON stage_planrates_clean("State", "HiosPlanID", "Year");';
    execute sql_code;

    sql_code := 'CREATE VIEW public.vw_stage_planrates_raw 
                 AS
                  SELECT * FROM ' || full_table_name || ';';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE VIEW public.vw_plansrates_updates 
                AS    
                SELECT
                    p."State" as "State"
                    ,p."Year" as "plan_year"
                    ,cast(null as varchar(30)) as "HIOS Carrier ID"
                    ,p."Carrier" as "Carrier"
                    ,p."CarrierFriendlyName" as "Carrier Marketing Name"
                    ,p."HiosPlanID" as "Hios Plan ID"
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
                    WHERE   EXISTS (SELECT 1 FROM public.vw_stage_planrates_raw as s 
                                    WHERE s."plan_year" = p."Year" 
                                    and s."Hios Plan ID" = p."HiosPlanID" 
                                    AND s."State" = p."State");';
    execute sql_code;
    
END;
$$;
/*
    ) AS
                SELECT *
                FROM public."Plans" WHERE 1 = 0 WITH NO DATA;
*/