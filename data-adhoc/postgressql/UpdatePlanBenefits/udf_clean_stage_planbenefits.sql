-- DROP FUNCTION udf_clean_stage_planbenefits();
CREATE OR REPLACE FUNCTION udf_clean_stage_planbenefits() RETURNS void 
        LANGUAGE plpgsql
        AS $$
BEGIN

    DELETE FROM vw_stage_planbenefits WHERE "PlanBenefitID" is null and "HiosPlanID" is null;

    -- set values to match lookups
    UPDATE public.vw_stage_planbenefits pb
    SET    "CoinsuranceCopayOrder" = 'Copay+Coinsurance'
    WHERE  "CoinsuranceCopayOrder" = 'CopayCoinsurance';

    -- CoinsuranceCopayOrder is not null, default is empty string
    UPDATE public.vw_stage_planbenefits pb
    SET    "CoinsuranceCopayOrder" = ''
    WHERE  "CoinsuranceCopayOrder" is null;

    -- CopayAfterFirstVisits is not null, default is empty string
    UPDATE public.vw_stage_planbenefits pb
    SET    "CopayAfterFirstVisits" = -1
    WHERE  "CopayAfterFirstVisits" is null;

    -- copay day limit should be -1, never null.
    UPDATE public.vw_stage_planbenefits pb
    SET    "CopayDayLimit" = -1
    WHERE  "CopayDayLimit" is null;

    -- copay day limit should be -1, never null.
    UPDATE public.vw_stage_planbenefits pb 
    SET    "CoverageVisitLimit" = -1
    WHERE  "CoverageVisitLimit" is null;

    UPDATE public.vw_stage_planbenefits pb 
    SET    "Coinsurance" = -1 
    WHERE  "Coinsurance" IS NULL 
    AND    "CopayAmount" is not null;

END;
$$;
