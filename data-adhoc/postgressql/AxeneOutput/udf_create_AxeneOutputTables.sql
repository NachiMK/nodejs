-- DROP FUNCTION udf_create_AxeneOutputTables();
CREATE OR REPLACE FUNCTION udf_create_AxeneOutputTables() RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
        sql_code VARCHAR;
BEGIN

    sql_code := '
    CREATE TABLE IF NOT EXISTS public."TempAVReport" AS 
    SELECT   AO."ID"
            ,AO."FileName" as "fileName"
            ,AO."ModeledMetalTier"
            ,AO."PlanID"
            ,AO."ActuarialValue"
            ,CAST(NULL AS VARCHAR(255))as "HixmePlusColName"
            ,CAST(NULL AS NUMERIC) as "HixmePlusAddOnValue"
            ,AO."HixmeValue"
            ,CAST(NULL AS INT) AS "OriginalID"
            ,"BatchID"
    FROM    "AxeneOutputValues" AS AO
    WHERE   1 = 0;';
    raise notice '%',sql_code;
    execute sql_code;

    sql_code := 'CREATE TABLE IF NOT EXISTS public."TempAVPivot"
        (
         "OriginalID"  INT NOT NULL
        ,"0" NUMERIC
        ,"500" NUMERIC
        ,"1000" NUMERIC
        ,"1500" NUMERIC
        ,"2000" NUMERIC
        ,"2500" NUMERIC
      );';
    raise notice '%',sql_code;
    execute sql_code;
END;
$$;