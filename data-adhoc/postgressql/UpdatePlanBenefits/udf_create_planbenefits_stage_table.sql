-- DROP FUNCTION udf_create_planbenefits_stage_table(varchar(255));
CREATE OR REPLACE FUNCTION udf_create_planbenefits_stage_table(table_name VARCHAR(255)) RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
        sql_code VARCHAR;
        full_table_name VARCHAR;
BEGIN

    full_table_name := (SELECT 'public.stage_planbenefits_' 
                        || coalesce(table_name, '') 
                        || '_' 
                        || to_char(current_timestamp, 'YYYYMMDD'));
    
    EXECUTE 'DROP VIEW IF EXISTS public.vw_planbenefits_updates;';
    EXECUTE 'DROP VIEW IF EXISTS public.vw_stage_planbenefits;';
	EXECUTE 'DROP TABLE IF EXISTS ' || full_table_name || ';';
	
    sql_code := 'CREATE TABLE IF NOT EXISTS ' || full_table_name || ' AS
                SELECT
                    "PlanBenefitID"
                    ,"Year"
                    ,"HiosPlanID"
                    ,CAST(null as varchar(10)) as "State"
                    ,"Benefit"
                    ,"ServiceNotCovered"
                    ,"AppliesToDeductible"
                    ,"Coinsurance"
                    ,"CopayAmount"
                    ,"CopayDayLimit"
                    ,"CoinsuranceCopayOrder"
                    ,"MemberServicePaidCap"
                    ,"CoverageVisitLimit"
                    ,"FirstDollarVisits"
                    ,"IsGrouped"
                    ,"CopayAfterFirstVisits"
                    ,"Notes"
                    ,CAST(null as uuid) as "ClusterID"
                FROM public."PlanBenefits" WHERE 1 = 0 WITH NO DATA;';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE VIEW public.vw_stage_planbenefits 
                 AS
                  SELECT * FROM ' || full_table_name || ';';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE VIEW public.vw_planbenefits_updates 
                AS    
                    SELECT 
                         "PlanBenefitID"
                        ,p."Year"
                        ,p."HiosPlanID"
                        ,p."State"
                        ,"Benefit"
                        ,"ServiceNotCovered"
                        ,"AppliesToDeductible"
                        ,"Coinsurance"
                        ,"CopayAmount"
                        ,"CopayDayLimit"
                        ,"CoinsuranceCopayOrder"
                        ,"MemberServicePaidCap"
                        ,"CoverageVisitLimit"
                        ,"FirstDollarVisits"
                        ,"IsGrouped"
                        ,"CopayAfterFirstVisits"
                        ,CAST('''' as VARCHAR(200)) as "Notes"
                        ,p."GroupID" AS "ClusterID"
                    FROM "Plans" as p
                    INNER
                    JOIN "PlanBenefits"  as pb ON p."HiosPlanID" = pb."HiosPlanID" 
                                        AND p."Year" = pb."Year"
                                        AND "Benefit"  NOT IN 
                                            (''MentalHealthProfessionalOutpatient''
                                            ,''HabilitationServices''
                                            ,''OtherPractitionerOfficeVisit''
                                            ,''OutpatientRehabilitationServices''
                                            ,''PreventiveCare'')
                    WHERE   1 = 1
                    AND     EXISTS (SELECT 1 FROM vw_stage_planbenefits as v WHERE v."HiosPlanID" = p."HiosPlanID" AND v."Year" = p."Year");';
    execute sql_code;

END;
$$;