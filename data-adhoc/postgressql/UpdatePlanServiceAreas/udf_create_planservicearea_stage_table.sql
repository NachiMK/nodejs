-- DROP FUNCTION udf_create_planservicearea_stage_table(varchar(255));
CREATE OR REPLACE FUNCTION udf_create_planservicearea_stage_table(table_name VARCHAR(255)) RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
        sql_code VARCHAR;
        full_table_name VARCHAR;
BEGIN

    full_table_name := (SELECT 'public.stage_planservicearea_' 
                        || coalesce(table_name, '') 
                        || '_' 
                        || to_char(current_timestamp, 'YYYYMMDD'));
    
    EXECUTE 'DROP VIEW IF EXISTS public.vw_stage_planserviceareas;';
	EXECUTE 'DROP TABLE IF EXISTS ' || full_table_name || ';';
	
    sql_code := 'CREATE TABLE IF NOT EXISTS ' || full_table_name || '
        (
            "PlanServiceAreaID"        INT
            ,"Year"                     INT            
            ,"State"                    VARCHAR(10)
            ,"IssuerID"                 VARCHAR(10)
            ,"SourceName"               VARCHAR(255)
            ,"HiosPlanID"               VARCHAR(24)
            ,"ServiceAreaID"            VARCHAR(255)
            ,"ServiceAreaName"          VARCHAR(255)
            ,"CoverEntireState"         VARCHAR(5)
            ,"CountyCode"               INT
            ,"PartialCounty"            VARCHAR(5)
            ,"Zipcode"                  VARCHAR(14)
            ,"IsActive"                 VARCHAR(5)
        );';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE VIEW public.vw_stage_planserviceareas 
                 AS
                  SELECT * FROM ' || full_table_name || ';';
    raise notice '%',sql_code;
    execute sql_code;

END;
$$;
/*
    ) AS
                SELECT
                     "PlanServiceAreaID"
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
                    ,"Year"
                    ,"IsActive"
                FROM public."PlanServiceAreas" WHERE 1 = 0 WITH NO DATA;
*/