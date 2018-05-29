-- DROP FUNCTION udf_create_plan_av_stage_table(varchar(255));
CREATE OR REPLACE FUNCTION udf_create_plan_av_stage_table(table_name VARCHAR(255)) RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
        sql_code VARCHAR;
        full_table_name VARCHAR;
BEGIN

    full_table_name := (SELECT 'public.stage_plans_av_raw_' 
                        || coalesce(table_name, '') 
                        || '_' 
                        || to_char(current_timestamp, 'YYYYMMDD'));
    
    EXECUTE 'DROP VIEW IF EXISTS public.vw_plans_av;';
    EXECUTE 'DROP VIEW IF EXISTS public.vw_stage_plan_av_raw;';
	EXECUTE 'DROP TABLE IF EXISTS ' || full_table_name || ';';
	
    sql_code := 'CREATE TABLE IF NOT EXISTS ' || full_table_name || '
        (
         "isOriginal"           VARCHAR(5)
        ,"fileName"             VARCHAR(255)
        ,"Year"                 INT
        ,"HiosPlanID"           VARCHAR(45)
        ,"PlanMarketingName"    VARCHAR(300)
        ,"State"                VARCHAR(10)
        ,"Carrier"              VARCHAR(250)
        ,"PlanType"             VARCHAR(15)
        ,"Metal"                VARCHAR(40)
        ,"IsHSA"                VARCHAR(5)
        ,"IsActive"             VARCHAR(5)
        ,"IsForSale"            VARCHAR(5)
        ,"IsApproved"           VARCHAR(5)
        ,"UseForModeling"       VARCHAR(5)
        ,"PlanID"               VARCHAR(100)
        ,"GroupID"              VARCHAR(100)
        ,"ActuarialValue"       numeric(12, 8)
        ,"HixmeValuePlus0"      numeric(12, 8)
        ,"HixmeValuePlus500"    numeric(12, 8)
        ,"HixmeValuePlus1000"   numeric(12, 8)
        ,"HixmeValuePlus1500"   numeric(12, 8)
        ,"HixmeValuePlus2000"   numeric(12, 8)
        ,"HixmeValuePlus2500"   numeric(12, 8)
      );';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE TABLE IF NOT EXISTS public.stage_plans_av_clean
        (
         "Plans_AV_StageID"     SERIAL          NOT NULL
        ,"SourceID"             VARCHAR(255)    NOT NULL
        ,"Year"                 INT             NOT NULL
        ,"HiosPlanID"           VARCHAR(45)     NOT NULL
        ,"State"                VARCHAR(10)     NOT NULL
        ,"PlanID"               VARCHAR(100)    NOT NULL
        ,"IsHSA"                BOOLEAN         NOT NULL
        ,"IsActive"             BOOLEAN         NOT NULL
        ,"IsForSale"            BOOLEAN         NOT NULL
        ,"IsApproved"           BOOLEAN         NOT NULL
        ,"UseForModeling"       BOOLEAN         NOT NULL
        ,"GroupID"              VARCHAR(100)    NOT NULL
        ,"ActuarialValue"       numeric(12, 8)  NULL
        ,"HixmeValuePlus0"      numeric(12, 8)  NULL
        ,"HixmeValuePlus500"    numeric(12, 8)  NULL
        ,"HixmeValuePlus1000"   numeric(12, 8)  NULL
        ,"HixmeValuePlus1500"   numeric(12, 8)  NULL
        ,"HixmeValuePlus2000"   numeric(12, 8)  NULL
        ,"HixmeValuePlus2500"   numeric(12, 8)  NULL
        ,"CreatedDate"          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
        ,"StageTableName"       VARCHAR(200)    NOT NULL
      );';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE UNIQUE INDEX IF NOT EXISTS UNQ_stage_plans_av_clean
                    ON stage_plans_av_clean("StageTableName", "PlanID", "HiosPlanID", "Year");';
    execute sql_code;

    sql_code := 'CREATE INDEX IF NOT EXISTS IDX_stage_plans_av_clean_HIOS_Year
                    ON stage_plans_av_clean("HiosPlanID", "Year");';
    execute sql_code;

    sql_code := 'CREATE INDEX IF NOT EXISTS IDX_stage_plans_av_clean_Source_Plan
                ON stage_plans_av_clean("SourceID", "PlanID");';
    execute sql_code;

    sql_code := 'CREATE VIEW public.vw_stage_plan_av_raw 
                 AS
                  SELECT * FROM ' || full_table_name || ' WHERE COALESCE(UPPER("isOriginal"), ''FALSE'') = ''TRUE'';';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE VIEW public.vw_plans_av 
                AS    
                SELECT 
                        CAST(''TRUE'' as VARCHAR(5)) as "isOriginal"
                        ,CAST('''' as VARCHAR(255)) as "fileName"
                        ,p."Year"
                        ,p."HiosPlanID"
                        ,p."PlanMarketingName"
                        ,p."State"
                        ,p."Carrier"
                        ,p."PlanType"
                        ,p."Metal"
                        ,CAST(p."IsHSA" as VARCHAR(5)) AS "IsHSA"
                        ,CAST(p."IsActive" as VARCHAR(5)) AS "IsActive"
                        ,CAST(p."IsForSale" as VARCHAR(5)) AS "IsForSale"
                        ,CAST(p."IsApproved" as VARCHAR(5)) AS "IsApproved"
                        ,CAST(p."UseForModeling" as VARCHAR(5)) AS "UseForModeling"
                        ,p."PlanID"
                        ,p."GroupID"
                        ,p."ActuarialValue"	
                        ,p."HixmeValuePlus0"
                        ,p."HixmeValuePlus500"
                        ,p."HixmeValuePlus1000"
                        ,p."HixmeValuePlus1500"
                        ,p."HixmeValuePlus2000"
                        ,p."HixmeValuePlus2500"
                        --,p."UpdatedDate"
                FROM    "Plans" as p
                WHERE   1 = 1
                AND     EXISTS (SELECT 1 FROM vw_stage_plan_av_raw as v WHERE v."PlanID" = CAST(p."PlanID" as VARCHAR) AND v."Year" = p."Year");';
    execute sql_code;
    
END;
$$;
/*
    ) AS
                SELECT *
                FROM public."Plans" WHERE 1 = 0 WITH NO DATA;
*/