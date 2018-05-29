-- DROP FUNCTION udf_clean_stage_planrates();
CREATE OR REPLACE FUNCTION udf_clean_stage_planrates() RETURNS void 
        LANGUAGE plpgsql
        AS $$
BEGIN

    DELETE FROM vw_stage_planrates_raw WHERE "Hios Plan ID" is null;
    DELETE FROM vw_stage_planrates_raw WHERE "plan_year" is null;
    DELETE FROM vw_stage_planrates_raw WHERE "State" is null;

    UPDATE vw_stage_planrates_raw
    SET    "HSA" = 'TRUE'
    WHERE  UPPER(TRIM("HSA")) IN ('X', 'YES', 'TRUE');

    UPDATE vw_stage_planrates_raw
    SET    "HSA" = 'FALSE'
    WHERE  "HSA" IS null
    OR     "HSA" = ''
    OR     "HSA" = 'No'
    OR     "HSA" = 'NO';

    UPDATE vw_stage_planrates_raw
    SET    "is_for_sale" = 'TRUE'
    WHERE  UPPER(TRIM("is_for_sale")) IN ('X', 'YES', 'TRUE');

    UPDATE vw_stage_planrates_raw
    SET    "is_for_sale" = 'FALSE'
    WHERE  "is_for_sale" is null
    OR     "is_for_sale" = ''
    OR     "is_for_sale" = 'No'
    OR     "is_for_sale" = 'NO';

    UPDATE vw_stage_planrates_raw
    SET    "is_active" = 'TRUE'
    WHERE  UPPER(TRIM("is_active")) IN ('X', 'YES', 'TRUE');

    UPDATE vw_stage_planrates_raw
    SET    "is_active" = 'TRUE'
    WHERE  "is_active" is null
    OR     "is_active" = '';

    UPDATE vw_stage_planrates_raw
    SET    "is_active" = 'FALSE'
    WHERE  "is_active" = 'No'
    OR     "is_active" = 'NO';

    UPDATE vw_stage_planrates_raw
    SET    "use_for_modeling" = 'TRUE'
    WHERE  UPPER(TRIM("use_for_modeling")) IN ('X', 'YES', 'TRUE');

    UPDATE vw_stage_planrates_raw
    SET    "use_for_modeling" = 'FALSE'
    WHERE  "use_for_modeling" is null
    OR     "use_for_modeling" = ''
    OR     "use_for_modeling" = 'No'
    OR     "use_for_modeling" = 'NO';

END;
$$;
