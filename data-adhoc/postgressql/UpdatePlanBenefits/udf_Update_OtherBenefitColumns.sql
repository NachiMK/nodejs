DROP FUNCTION IF EXISTS public.udf_Update_OtherBenefitColumns();
-- DROP FUNCTION udf_Update_OtherBenefitColumns();
CREATE OR REPLACE FUNCTION udf_Update_OtherBenefitColumns() RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
    sql_code VARCHAR;
    rcnt INT;
    update_dt_time timestamp;
BEGIN
    /* 
        This function updates the following columns
    
        AppliesToMOOP (always TRUE if Benefits != PreventiveCare)
        SBCValue (set to '')
        SBCCleanValue (set to '')
        BenefitDisplayValue (set to '') -- to be replaced with a formula
        BenefitDisplayGroup (set to '') -- based on BenefitGenerator2 table
    */

    -- update AppliesToMOOP
    UPDATE  "PlanBenefits" AS PB
    SET      "AppliesToMOOP" = CASE WHEN PB."Benefit" = 'PreventiveCare' THEN FALSE ELSE TRUE END
    FROM    public.vw_stage_planbenefits as stg
    WHERE   (
                (pb."PlanBenefitID" = stg."PlanBenefitID" AND stg."PlanBenefitID" > 0)
            OR  (   (stg."PlanBenefitID" < 0)
                AND (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" = pb."Benefit")
                )
            )
    AND     stg."Year" = pb."Year"
    AND     stg."HiosPlanID" = pb."HiosPlanID"
    AND     PB."AppliesToMOOP" IS NULL;

    raise notice 'Rows Updated or Inserted at: %', update_dt_time;

END;
$$;
/*
    -- testing code
    SELECT 
    SELECT udf_Update_OtherBenefitColumns();
*/