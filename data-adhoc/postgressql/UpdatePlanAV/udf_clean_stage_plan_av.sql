-- DROP FUNCTION udf_clean_stage_plan_av();
CREATE OR REPLACE FUNCTION udf_clean_stage_plan_av() RETURNS void 
        LANGUAGE plpgsql
        AS $$
BEGIN

    DELETE FROM vw_stage_plan_av_raw WHERE "HiosPlanID" is null;
    DELETE FROM vw_stage_plan_av_raw WHERE "Year" is null;
    DELETE FROM vw_stage_plan_av_raw WHERE "PlanID" is null;
    DELETE FROM vw_stage_plan_av_raw WHERE "State" is null;

    -- DELETE ANYTHING NOT ORIGINAL
    -- DELETE FROM vw_stage_plan_av_raw
    -- WHERE   "isOriginal" IS NULL
    -- OR      "isOriginal" = ''
    -- OR      "isOriginal" = 'FALSE';

    UPDATE vw_stage_plan_av_raw
    SET    "IsHSA" = 'TRUE'
    WHERE  UPPER(TRIM("IsHSA")) IN ('X', 'YES', 'TRUE', 'Yes', 'yes', 'true');

    UPDATE vw_stage_plan_av_raw
    SET    "IsHSA" = 'FALSE'
    WHERE  "IsHSA" IS null
    OR     "IsHSA" = ''
    OR     "IsHSA" = 'No'
    OR     "IsHSA" = 'NO';

    UPDATE vw_stage_plan_av_raw
    SET    "IsForSale" = 'TRUE'
    WHERE  UPPER(TRIM("IsForSale")) IN ('X', 'YES', 'TRUE', 'Yes', 'yes', 'true');

    UPDATE vw_stage_plan_av_raw
    SET    "IsForSale" = 'FALSE'
    WHERE  "IsForSale" is null
    OR     "IsForSale" = ''
    OR     "IsForSale" = 'No'
    OR     "IsForSale" = 'NO';

    UPDATE vw_stage_plan_av_raw
    SET    "IsActive" = 'TRUE'
    WHERE  UPPER(TRIM("IsActive")) IN ('X', 'YES', 'TRUE', 'Yes', 'yes', 'true');

    UPDATE vw_stage_plan_av_raw
    SET    "IsActive" = 'TRUE'
    WHERE  "IsActive" is null
    OR     "IsActive" = '';

    UPDATE vw_stage_plan_av_raw
    SET    "IsActive" = 'FALSE'
    WHERE  "IsActive" = 'No'
    OR     "IsActive" = 'NO';

    UPDATE vw_stage_plan_av_raw
    SET    "IsApproved" = 'TRUE'
    WHERE  UPPER(TRIM("IsApproved")) IN ('X', 'YES', 'TRUE', 'Yes', 'yes', 'true');

    UPDATE vw_stage_plan_av_raw
    SET    "IsApproved" = 'FALSE'
    WHERE  "IsApproved" is null
    OR     "IsApproved" = ''
    OR     "IsApproved" = 'No'
    OR     "IsApproved" = 'NO';

    UPDATE vw_stage_plan_av_raw
    SET    "UseForModeling" = 'TRUE'
    WHERE  UPPER(TRIM("UseForModeling")) IN ('X', 'YES', 'TRUE', 'Yes', 'yes', 'true');

    UPDATE vw_stage_plan_av_raw
    SET    "UseForModeling" = 'FALSE'
    WHERE  "UseForModeling" is null
    OR     "UseForModeling" = ''
    OR     "UseForModeling" = 'No'
    OR     "UseForModeling" = 'NO';

    UPDATE vw_stage_plan_av_raw
    SET    "ActuarialValue" = null
    WHERE  "ActuarialValue" = -1;

    UPDATE vw_stage_plan_av_raw
    SET    "HixmeValuePlus0" = null
    WHERE  "HixmeValuePlus0" = -1;

    UPDATE vw_stage_plan_av_raw
    SET    "HixmeValuePlus500" = null
    WHERE  "HixmeValuePlus500" = -1;

    UPDATE vw_stage_plan_av_raw
    SET    "HixmeValuePlus1000" = null
    WHERE  "HixmeValuePlus1000" = -1;

    UPDATE vw_stage_plan_av_raw
    SET    "HixmeValuePlus1500" = null
    WHERE  "HixmeValuePlus1500" = -1;

    UPDATE vw_stage_plan_av_raw
    SET    "HixmeValuePlus2000" = null
    WHERE  "HixmeValuePlus2000" = -1;

    UPDATE vw_stage_plan_av_raw
    SET    "HixmeValuePlus2500" = null
    WHERE  "HixmeValuePlus2500" = -1;

END;
$$;
