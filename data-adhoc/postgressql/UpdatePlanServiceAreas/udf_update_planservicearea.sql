-- DROP FUNCTION udf_update_planserviceareas(BOOLEAN);
CREATE OR REPLACE FUNCTION udf_update_planserviceareas(DeleteServiceAreaForIssuers BOOLEAN) RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
    sql_code VARCHAR;
    full_table_name VARCHAR;
    rcnt INT;
    update_dt_time timestamp;
BEGIN

    full_table_name := (SELECT 'public.PlanServiceAreas_BAK_' 
                        || to_char(current_timestamp, 'YYYYMMDDHH24MISS'));

    -- backup
    EXECUTE 'DROP TABLE IF EXISTS ' || full_table_name || ';';
    sql_code := 'CREATE TABLE IF NOT EXISTS ' || full_table_name || ' AS
                SELECT *
                FROM    public."PlanServiceAreas" as pb
                WHERE   EXISTS (SELECT 1  FROM public.vw_stage_planserviceareas as stg 
                                WHERE pb."PlanServiceAreaID" = stg."PlanServiceAreaID");';
    raise notice '%', sql_code;
    execute sql_code;

    -- count in backup
    EXECUTE 'SELECT count(*) as cnt_in_backup from ' || full_table_name || ';' INTO rcnt;
    raise notice 'Backup Count: %',rcnt;

    -- capture date time
    update_dt_time := (SELECT current_timestamp);

    DELETE FROM "PlanServiceAreas" as pb
    WHERE EXISTS    (
                        SELECT  1
                        FROM    public.vw_stage_planserviceareas as stg 
                        WHERE   pb."Year"          = stg."Year"
                        AND     pb."IssuerID"      = stg."IssuerID"
                        AND     pb."State"         = stg."State"
                    )
    AND   COALESCE(DeleteServiceAreaForIssuers, false) = true;

    -- update
    UPDATE  public."PlanServiceAreas" AS psa
    SET     --  psa."State" = stg."State"
            -- ,psa."IssuerID" = stg."IssuerID"
            -- ,psa."SourceName" = stg."SourceName"
            -- ,psa."HiosPlanID" = stg."HiosPlanID"
            -- ,psa."ServiceAreaID" = stg."ServiceAreaID"
             "ServiceAreaName" = stg."ServiceAreaName"
            ,"CoverEntireState" = CAST(stg."CoverEntireState" as BOOLEAN)
            -- ,psa."CountyCode" = stg."CountyCode"
            ,"PartialCounty" = CAST(stg."PartialCounty" as BOOLEAN)
            -- ,psa."Zipcode" = stg."Zipcode"
            ,"IsActive" = CAST(stg."IsActive" as BOOLEAN)
            ,"UpdatedDate" = update_dt_time
    FROM    public.vw_stage_planserviceareas as stg
    WHERE   psa."PlanServiceAreaID" = stg."PlanServiceAreaID"
    AND     stg."PlanServiceAreaID" > 0
    AND     stg."Year" = psa."Year"
    AND     (
                0 = 1
            --    ((stg."State" != psa."State" AND stg."State" IS NOT NULL AND psa."State" IS NOT NULL) OR (stg."State" IS NULL AND psa."State" IS NOT NULL) OR (stg."State" IS NOT NULL AND psa."State" IS NULL))
            -- OR ((stg."IssuerID" != psa."IssuerID" AND stg."IssuerID" IS NOT NULL AND psa."IssuerID" IS NOT NULL) OR (stg."IssuerID" IS NULL AND psa."IssuerID" IS NOT NULL) OR (stg."IssuerID" IS NOT NULL AND psa."IssuerID" IS NULL))
            -- OR ((stg."SourceName" != psa."SourceName" AND stg."SourceName" IS NOT NULL AND psa."SourceName" IS NOT NULL) OR (stg."SourceName" IS NULL AND psa."SourceName" IS NOT NULL) OR (stg."SourceName" IS NOT NULL AND psa."SourceName" IS NULL))
            -- OR ((stg."HiosPlanID" != psa."HiosPlanID" AND stg."HiosPlanID" IS NOT NULL AND psa."HiosPlanID" IS NOT NULL) OR (stg."HiosPlanID" IS NULL AND psa."HiosPlanID" IS NOT NULL) OR (stg."HiosPlanID" IS NOT NULL AND psa."HiosPlanID" IS NULL))
            -- OR ((stg."ServiceAreaID" != psa."ServiceAreaID" AND stg."ServiceAreaID" IS NOT NULL AND psa."ServiceAreaID" IS NOT NULL) OR (stg."ServiceAreaID" IS NULL AND psa."ServiceAreaID" IS NOT NULL) OR (stg."ServiceAreaID" IS NOT NULL AND psa."ServiceAreaID" IS NULL))
            OR ((stg."ServiceAreaName" != psa."ServiceAreaName" AND stg."ServiceAreaName" IS NOT NULL AND psa."ServiceAreaName" IS NOT NULL) OR (stg."ServiceAreaName" IS NULL AND psa."ServiceAreaName" IS NOT NULL) OR (stg."ServiceAreaName" IS NOT NULL AND psa."ServiceAreaName" IS NULL))
            OR ((CAST(stg."CoverEntireState" as BOOLEAN) != psa."CoverEntireState" AND stg."CoverEntireState" IS NOT NULL AND psa."CoverEntireState" IS NOT NULL) OR (stg."CoverEntireState" IS NULL AND psa."CoverEntireState" IS NOT NULL) OR (stg."CoverEntireState" IS NOT NULL AND psa."CoverEntireState" IS NULL))
            --OR ((stg."CountyCode" != psa."CountyCode" AND stg."CountyCode" IS NOT NULL AND psa."CountyCode" IS NOT NULL) OR (stg."CountyCode" IS NULL AND psa."CountyCode" IS NOT NULL) OR (stg."CountyCode" IS NOT NULL AND psa."CountyCode" IS NULL))
            OR ((CAST(stg."PartialCounty" as BOOLEAN) != psa."PartialCounty" AND stg."PartialCounty" IS NOT NULL AND psa."PartialCounty" IS NOT NULL) OR (stg."PartialCounty" IS NULL AND psa."PartialCounty" IS NOT NULL) OR (stg."PartialCounty" IS NOT NULL AND psa."PartialCounty" IS NULL))
            --OR ((stg."Zipcode" != psa."Zipcode" AND stg."Zipcode" IS NOT NULL AND psa."Zipcode" IS NOT NULL) OR (stg."Zipcode" IS NULL AND psa."Zipcode" IS NOT NULL) OR (stg."Zipcode" IS NOT NULL AND psa."Zipcode" IS NULL))
            OR ((CAST(stg."IsActive" as BOOLEAN) != psa."IsActive" AND stg."IsActive" IS NOT NULL AND psa."IsActive" IS NOT NULL) OR (stg."IsActive" IS NULL AND psa."IsActive" IS NOT NULL) OR (stg."IsActive" IS NOT NULL AND psa."IsActive" IS NULL))
            );

    -- Insert new plans
    INSERT INTO
            public."PlanServiceAreas"
            (
            "Year"
            ,"State"
            ,"IssuerID"
            ,"SourceName"
            ,"HiosPlanID"
            ,"ServiceAreaID"
            ,"ServiceAreaName"
            ,"CoverEntireState"
            ,"CountyCode"
            ,"PartialCounty"
            ,"Zipcode"
            ,"IsActive"
            ,"CreatedDate"
            ,"UpdatedDate"
            )
    SELECT  stg."Year"
            ,stg."State"
            ,stg."IssuerID"
            ,stg."SourceName"
            ,stg."HiosPlanID"
            ,stg."ServiceAreaID"
            ,stg."ServiceAreaName"
            ,CAST(stg."CoverEntireState" AS BOOLEAN) AS "CoverEntireState"
            ,stg."CountyCode"
            ,CAST(stg."PartialCounty" AS BOOLEAN) AS "PartialCounty"
            ,stg."Zipcode"
            ,CAST(stg."IsActive" AS BOOLEAN) AS "IsActive" 
            ,update_dt_time as "CreatedDate"
            ,update_dt_time as "UpdatedDate"
    FROM    public.vw_stage_planserviceareas as stg
    WHERE   NOT EXISTS (SELECT  1
                        FROM    public."PlanServiceAreas" as pb 
                        WHERE   stg."Year"          = pb."Year"
                        AND     stg."HiosPlanID"    = pb."HiosPlanID"
                        AND     pb."IssuerID"       = stg."IssuerID"
                        AND     pb."ServiceAreaID"  = stg."ServiceAreaID"
                        AND     pb."State"          = stg."State"
                        AND     COALESCE(pb."CountyCode", '0')   = COALESCE(stg."CountyCode", '0')
                        AND     COALESCE(pb."Zipcode", '0') = COALESCE(stg."Zipcode", '0')
                        )
    AND     stg."PlanServiceAreaID" < 0 -- Negative in here means new plans
    ;

    -- Find count after update
    rcnt:=
        (
            SELECT   count(*) 
            FROM     public.vw_stage_planserviceareas as stg
            INNER 
            JOIN    public."PlanServiceAreas" as psa ON   psa."PlanServiceAreaID" = stg."PlanServiceAreaID"
            WHERE   
                (
                    0 = 1
                    OR ((stg."ServiceAreaName" != psa."ServiceAreaName" AND stg."ServiceAreaName" IS NOT NULL AND psa."ServiceAreaName" IS NOT NULL) OR (stg."ServiceAreaName" IS NULL AND psa."ServiceAreaName" IS NOT NULL) OR (stg."ServiceAreaName" IS NOT NULL AND psa."ServiceAreaName" IS NULL))
                    OR ((CAST(stg."CoverEntireState" AS BOOLEAN) != psa."CoverEntireState" AND stg."CoverEntireState" IS NOT NULL AND psa."CoverEntireState" IS NOT NULL) OR (stg."CoverEntireState" IS NULL AND psa."CoverEntireState" IS NOT NULL) OR (stg."CoverEntireState" IS NOT NULL AND psa."CoverEntireState" IS NULL))
                    OR ((CAST(stg."PartialCounty" AS BOOLEAN) != psa."PartialCounty" AND stg."PartialCounty" IS NOT NULL AND psa."PartialCounty" IS NOT NULL) OR (stg."PartialCounty" IS NULL AND psa."PartialCounty" IS NOT NULL) OR (stg."PartialCounty" IS NOT NULL AND psa."PartialCounty" IS NULL))
                    OR ((CAST(stg."IsActive" AS BOOLEAN) != psa."IsActive" AND stg."IsActive" IS NOT NULL AND psa."IsActive" IS NOT NULL) OR (stg."IsActive" IS NULL AND psa."IsActive" IS NOT NULL) OR (stg."IsActive" IS NOT NULL AND psa."IsActive" IS NULL))
                )
        );

    raise notice 'Count After Update, Should be Zero : %',rcnt;
    raise notice 'Rows Updated or Inserted at: %', update_dt_time;

END;
$$;