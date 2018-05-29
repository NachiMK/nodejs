-- DROP FUNCTION udf_clean_stage_planserviceareas();
CREATE OR REPLACE FUNCTION udf_clean_stage_planserviceareas() RETURNS void 
        LANGUAGE plpgsql
        AS $$
BEGIN

    DELETE FROM vw_stage_planserviceareas WHERE "IssuerID" is null;
    DELETE FROM vw_stage_planserviceareas WHERE "HiosPlanID" is null;
    DELETE FROM vw_stage_planserviceareas WHERE "Year" is null;
    DELETE FROM vw_stage_planserviceareas WHERE "ServiceAreaID" is null;
    DELETE FROM vw_stage_planserviceareas WHERE "State" is null;

    UPDATE vw_stage_planserviceareas
    SET    "CoverEntireState" = 'TRUE'
    WHERE  UPPER(TRIM("CoverEntireState")) IN ('X', 'YES', 'TRUE');

    UPDATE vw_stage_planserviceareas
    SET    "CoverEntireState" = 'FALSE'
    WHERE  "CoverEntireState" IS null
    OR     "CoverEntireState" = ''
    OR     "CoverEntireState" = 'No'
    OR     "CoverEntireState" = 'NO';

    UPDATE vw_stage_planserviceareas
    SET    "PartialCounty" = 'TRUE'
    WHERE  UPPER(TRIM("PartialCounty")) IN ('X', 'YES', 'TRUE');

    UPDATE vw_stage_planserviceareas
    SET    "PartialCounty" = 'FALSE'
    WHERE  "PartialCounty" is null
    OR     "PartialCounty" = ''
    OR     "PartialCounty" = 'No'
    OR     "PartialCounty" = 'NO';

    UPDATE vw_stage_planserviceareas
    SET    "IsActive" = 'TRUE'
    WHERE  UPPER(TRIM("IsActive")) IN ('X', 'YES', 'TRUE');

    UPDATE vw_stage_planserviceareas
    SET    "IsActive" = 'TRUE'
    WHERE  "IsActive" is null
    OR     "IsActive" = '';

    UPDATE vw_stage_planserviceareas
    SET    "Zipcode" = null
    WHERE  "Zipcode" = '-1';

    UPDATE vw_stage_planserviceareas
    SET    "CountyCode" = null
    WHERE  "CountyCode" = '-1';

END;
$$;
