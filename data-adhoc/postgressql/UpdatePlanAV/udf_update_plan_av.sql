-- DROP FUNCTION udf_update_plan_av(VARCHAR(255));
CREATE OR REPLACE FUNCTION udf_update_plan_av(table_name VARCHAR(255)) RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
    sql_code VARCHAR;
    full_table_name VARCHAR;
    stage_table_name VARCHAR;
    rcnt INT;
    update_dt_time timestamp;
BEGIN

    full_table_name := (SELECT 'public.Plans_AV_BAK_' 
                        || to_char(current_timestamp, 'YYYYMMDDHH24MISS'));

    stage_table_name := (SELECT 'public.stage_plans_av_raw_' 
                        || coalesce(table_name, '') 
                        || '_' 
                        || to_char(current_timestamp, 'YYYYMMDD'));

    -- backup
    EXECUTE 'DROP TABLE IF EXISTS ' || full_table_name || ';';
    sql_code := 'CREATE TABLE IF NOT EXISTS ' || full_table_name || ' AS
                SELECT *
                FROM    public."Plans" as p
                WHERE   EXISTS (SELECT 1  FROM public.vw_stage_plan_av_raw as stg 
                                WHERE (     (CAST(p."PlanID" as VARCHAR) = stg."PlanID")
                                        OR  ((p."Year" = stg."Year") AND (p."HiosPlanID" = stg."HiosPlanID"))
                                      )
                                );';
    raise notice '%', sql_code;
    execute sql_code;

    -- count in backup
    EXECUTE 'SELECT count(*) as cnt_in_backup from ' || full_table_name || ';' INTO rcnt;
    raise notice 'Backup Count: %',rcnt;

    -- capture date time
    update_dt_time := (SELECT current_timestamp);

    --BEGIN;

    -- Add from Raw to clean
    INSERT INTO
        public.stage_plans_av_clean
        (
             "SourceID"
            ,"Year"
            ,"HiosPlanID"
            ,"State"
            ,"PlanID"
            ,"IsHSA"
            ,"IsActive"
            ,"IsForSale"
            ,"IsApproved"
            ,"UseForModeling"
            ,"GroupID"
            ,"ActuarialValue"    
            ,"HixmeValuePlus0"   
            ,"HixmeValuePlus500" 
            ,"HixmeValuePlus1000"
            ,"HixmeValuePlus1500"
            ,"HixmeValuePlus2000"
            ,"HixmeValuePlus2500"
            ,"CreatedDate"       
            ,"StageTableName"
        )
    SELECT   stg."fileName" as "SourceID"       
            ,stg."Year"
            ,stg."HiosPlanID"
            ,stg."State"
            ,stg."PlanID"
            ,COALESCE(CAST(stg."IsHSA" as BOOLEAN), false) as "IsHSA"
            ,COALESCE(CAST(stg."IsActive" as BOOLEAN), true) as "IsActive"
            ,COALESCE(CAST(stg."IsForSale" as BOOLEAN), true) as "IsForSale"
            ,COALESCE(CAST(stg."IsApproved" as BOOLEAN), true) as "IsApproved"
            ,COALESCE(CAST(stg."UseForModeling" as BOOLEAN), true) as "UseForModeling"
            ,COALESCE(stg."GroupID", '00000000-0000-0000-0000-000000000000') as "GroupID"
            ,stg."ActuarialValue"
            ,stg."HixmeValuePlus0"
            ,stg."HixmeValuePlus500"
            ,stg."HixmeValuePlus1000"
            ,stg."HixmeValuePlus1500"
            ,stg."HixmeValuePlus2000"
            ,stg."HixmeValuePlus2500"
            ,update_dt_time as "CreatedDate"
            ,stage_table_name as "StageTableName"
    FROM    vw_stage_plan_av_raw as stg
    WHERE   COALESCE(UPPER("isOriginal"), 'FALSE') = 'TRUE';

    -- update
    UPDATE  public."Plans" AS p
    SET     
             "ActuarialValue"       = stg."ActuarialValue"
            --,"IsHSA"                = stg."IsHSA"
            -- ,"IsActive"             = stg."IsActive"
            -- ,"IsForSale"            = stg."IsForSale"
            ,"IsApproved"           = CAST(stg."IsApproved" AS BOOLEAN)
            -- ,"UseForModeling"       = stg."UseForModeling"
            ,"HixmeValuePlus0"      = stg."HixmeValuePlus0"
            ,"HixmeValuePlus500"    = stg."HixmeValuePlus500"
            ,"HixmeValuePlus1000"   = stg."HixmeValuePlus1000"
            ,"HixmeValuePlus1500"   = stg."HixmeValuePlus1500"
            ,"HixmeValuePlus2000"   = stg."HixmeValuePlus2000"
            ,"HixmeValuePlus2500"   = stg."HixmeValuePlus2500"
            ,"UpdatedDate"          = update_dt_time
            ,"PlanLastModified"     = update_dt_time
    FROM    public.stage_plans_av_clean as stg
    WHERE   LENGTH(stg."PlanID") > 0
    AND     stg."Year" = p."Year"
    AND     stg."HiosPlanID" = p."HiosPlanID"
    AND     stg."PlanID" = CAST(p."PlanID" as VARCHAR)
    AND     stg."StageTableName" = stage_table_name
    AND     stg."CreatedDate" = update_dt_time
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
            );
    --COMMIT;

    -- Find count after update
    rcnt:=
        (
            SELECT   count(*) 
            FROM     public.stage_plans_av_clean as stg
            INNER 
            JOIN    public."Plans" as p ON  CAST(p."PlanID" as VARCHAR) = stg."PlanID"
            WHERE   LENGTH(stg."PlanID") > 0
            AND     stg."Year" = p."Year"
            AND     stg."HiosPlanID" = p."HiosPlanID"
            AND     stg."StageTableName" = stage_table_name
            AND     stg."CreatedDate" = update_dt_time
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
                        OR ((stg."IsApproved" != p."IsApproved" AND stg."IsApproved" IS NOT NULL AND p."IsApproved" IS NOT NULL) 
                            OR (stg."IsApproved" IS NULL AND p."IsApproved" IS NOT NULL) 
                            OR (stg."IsApproved" IS NOT NULL AND p."IsApproved" IS NULL))
                        OR ((stg."UseForModeling" != p."UseForModeling" AND stg."UseForModeling" IS NOT NULL AND p."UseForModeling" IS NOT NULL) 
                            OR (stg."UseForModeling" IS NULL AND p."UseForModeling" IS NOT NULL) 
                            OR (stg."UseForModeling" IS NOT NULL AND p."UseForModeling" IS NULL))
                        */
                    )
        );

    raise notice 'Count After Update, Should be Zero : %',rcnt;
    raise notice 'Rows Updated or Inserted at: %', update_dt_time;

END;
$$;