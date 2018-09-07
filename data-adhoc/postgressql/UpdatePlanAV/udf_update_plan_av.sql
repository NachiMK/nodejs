-- DROP FUNCTION udf_update_plan_av(VARCHAR(10));
CREATE OR REPLACE FUNCTION udf_update_plan_av(batchid VARCHAR(10)) 
RETURNS
    SETOF vw_AxeneOutputFormat AS $$
DECLARE
    sql_code VARCHAR;
    full_table_name VARCHAR;
    stage_table_name VARCHAR;
    rcnt INT;
    update_dt_time timestamp;
    retRecord public.vw_AxeneOutputFormat%rowtype;
BEGIN

    IF ((batchid IS NULL) OR (LENGTH(TRIM(batchid)) = 0)) THEN
        batchid := 'Minus1';
    END IF;

    stage_table_name := 'BatchId.' || batchid;

    full_table_name := (SELECT 'public.Plans_AV_BAK_' 
                        || batchid
                        || '_'
                        || to_char(current_timestamp, 'YYYYMMDDHH24MISS'));
    -- capture date time
    update_dt_time := (SELECT current_timestamp);

    INSERT INTO 
        stage_plans_av_clean
        (
            "SourceID"
            ,"Year"
            ,"HiosPlanID"
            ,"State"
            ,"IsHSA"
            ,"IsActive"
            ,"IsForSale"
            ,"IsApproved"
            ,"UseForModeling"
            ,"PlanID"
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
    SELECT
            "fileName" as "SourceID"
            ,"Year" as "Year"
            ,"HiosPlanID" as "HiosPlanID"
            ,"State" as "State"
            ,CAST("IsHSA" as BOOL) as "IsHSA"
            ,CAST("IsActive" as BOOL) as "IsActive"
            ,CAST("IsForSale" as BOOL) as "IsForSale"
            ,CAST("IsApproved" as BOOL) as "IsApproved"
            ,CAST("UseForModeling" as BOOL) as "UseForModeling"
            ,"PlanID" as "PlanID"
            ,"GroupID" as "GroupID"
            ,"ActuarialValue" as "ActuarialValue"
            ,"HixmeValuePlus0" as "HixmeValuePlus0"
            ,"HixmeValuePlus500" as "HixmeValuePlus500"
            ,"HixmeValuePlus1000" as "HixmeValuePlus1000"
            ,"HixmeValuePlus1500" as "HixmeValuePlus1500"
            ,"HixmeValuePlus2000" as "HixmeValuePlus2000"
            ,"HixmeValuePlus2500" as "HixmeValuePlus2500"
            ,update_dt_time AS "CreatedDate"
            ,stage_table_name as "StageTableName"
    FROM    public.udf_get_AxeneOutput(batchid)
    WHERE   "isOriginal" = 'TRUE'
    ON CONFLICT ("StageTableName", "PlanID", "HiosPlanID", "Year")
    DO NOTHING;

    -- backup
    EXECUTE 'DROP TABLE IF EXISTS ' || full_table_name || ';';
    sql_code := 'CREATE TABLE IF NOT EXISTS ' || full_table_name || ' AS
                SELECT *
                FROM    public."Plans" as p
                WHERE   EXISTS (SELECT 1  FROM public.stage_plans_av_clean as stg 
                                WHERE (     (CAST(p."PlanID" as VARCHAR) = stg."PlanID")
                                        OR  ((p."Year" = stg."Year") AND (p."HiosPlanID" = stg."HiosPlanID"))
                                      )
                                AND   "StageTableName" = ''' || stage_table_name || ''');';
    raise notice '%', sql_code;
    execute sql_code;

    -- count in backup
    EXECUTE 'SELECT count(*) as cnt_in_backup from ' || full_table_name || ';' INTO rcnt;
    raise notice 'Backup Count: %',rcnt;

    -- Update data
    UPDATE  public."Plans" AS p
    SET     
             "ActuarialValue"       = stg."ActuarialValue"
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
            );

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
                    )
        );

    raise notice 'Count After Update, Should be Zero : %',rcnt;
    raise notice 'Rows Updated or Inserted at: %', update_dt_time;

    sql_code := 'SELECT 
             true as "isOriginal"
            ,CAST(null as VARCHAR) as "fileName"
            ,"Year"
            ,"HiosPlanID"
            ,"PlanMarketingName"
            ,"State"
            ,"Carrier"
            ,"PlanType"
            ,"Metal"
            ,"IsHSA"
            ,"IsActive"
            ,"IsForSale"
            ,"IsApproved"
            ,"UseForModeling"
            ,"PlanID"
            ,"GroupID"
            ,"ActuarialValue"    
            ,"HixmeValuePlus0"   
            ,"HixmeValuePlus500" 
            ,"HixmeValuePlus1000"
            ,"HixmeValuePlus1500"
            ,"HixmeValuePlus2000"
            ,"HixmeValuePlus2500"
        FROM    public."Plans" AS P
        WHERE   EXISTS (SELECT  1 
                        FROM    stage_plans_av_clean as stg 
                        WHERE   P."Year" = stg."Year"
                        AND     P."HiosPlanID" = stg."HiosPlanID"
                        AND     stg."StageTableName" = ''' ||stage_table_name || '''
                        )
        AND     DATE_PART(''second'', ("UpdatedDate" - ''' || update_dt_time || ''')) BETWEEN 0 AND 1;';
    raise notice 'OUTPUT SQL %',sql_code;

    -- Result
    FOR retRecord in execute sql_code
    LOOP
        return next retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;

/*
    -- Testing code

*/