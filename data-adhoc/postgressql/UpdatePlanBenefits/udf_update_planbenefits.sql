-- DROP FUNCTION udf_update_planbenefits();
CREATE OR REPLACE FUNCTION udf_update_planbenefits() RETURNS void 
        LANGUAGE plpgsql
        AS $$
DECLARE
    sql_code VARCHAR;
    full_table_name VARCHAR;
    rcnt INT;
    update_dt_time timestamp;
BEGIN

    full_table_name := (SELECT 'public.PlanBenefits_BAK_' 
                        || to_char(current_timestamp, 'YYYYMMDDHH24MISS'));

    -- backup
    EXECUTE 'DROP TABLE IF EXISTS ' || full_table_name || ';';
    sql_code := 'CREATE TABLE IF NOT EXISTS ' || full_table_name || ' AS
                SELECT *
                FROM    public."PlanBenefits" as pb
                WHERE   EXISTS (SELECT 1  FROM public.vw_stage_planbenefits as stg 
                                WHERE pb."PlanBenefitID" = stg."PlanBenefitID");';
    raise notice '%', sql_code;
    execute sql_code;

    -- count in backup
    EXECUTE 'SELECT count(*) as cnt_in_backup from ' || full_table_name || ';' INTO rcnt;
    raise notice 'Backup Count: %',rcnt;

    -- capture date time
    update_dt_time := (SELECT current_timestamp);

    -- update
    UPDATE  public."PlanBenefits" pb
    SET      "Benefit" = stg."Benefit"
            ,"ServiceNotCovered" = stg."ServiceNotCovered"
            ,"AppliesToDeductible" = stg."AppliesToDeductible"
            ,"Coinsurance" = stg."Coinsurance"
            ,"CopayAmount" = stg."CopayAmount"
            ,"CopayDayLimit" = stg."CopayDayLimit"
            ,"CoinsuranceCopayOrder" = stg."CoinsuranceCopayOrder"
            ,"MemberServicePaidCap" = stg."MemberServicePaidCap"
            ,"CoverageVisitLimit" = stg."CoverageVisitLimit"
            ,"FirstDollarVisits" = stg."FirstDollarVisits"
            ,"IsGrouped" = stg."IsGrouped"
            ,"CopayAfterFirstVisits" = stg."CopayAfterFirstVisits"
            ,"UpdatedDate" = update_dt_time
    FROM    public.vw_stage_planbenefits as stg
    WHERE   (
                (pb."PlanBenefitID" = stg."PlanBenefitID" AND stg."PlanBenefitID" > 0)
            OR  (   (stg."PlanBenefitID" < 0)
                AND (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" = pb."Benefit")
                )
            )
    AND     stg."Year" = pb."Year"
    AND     stg."HiosPlanID" = pb."HiosPlanID"
    AND     (
                0 = 1
            OR (stg."Benefit" is null AND pb."Benefit" is not null) OR (stg."Benefit" is not null AND pb."Benefit" is null) OR (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" != pb."Benefit")
            OR (stg."ServiceNotCovered" is null AND pb."ServiceNotCovered" is not null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is not null and stg."ServiceNotCovered" != pb."ServiceNotCovered")
            OR (stg."AppliesToDeductible" is null AND pb."AppliesToDeductible" is not null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is not null and stg."AppliesToDeductible" != pb."AppliesToDeductible")
            OR (stg."Coinsurance" is null AND pb."Coinsurance" is not null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is not null and stg."Coinsurance" != pb."Coinsurance")
            OR (stg."CopayAmount" is null AND pb."CopayAmount" is not null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is not null and stg."CopayAmount" != pb."CopayAmount")
            OR (stg."CopayDayLimit" is null AND pb."CopayDayLimit" is not null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is not null and stg."CopayDayLimit" != pb."CopayDayLimit")
            OR (stg."CoinsuranceCopayOrder" is null AND pb."CoinsuranceCopayOrder" is not null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is not null and stg."CoinsuranceCopayOrder" != pb."CoinsuranceCopayOrder")
            OR (stg."MemberServicePaidCap" is null AND pb."MemberServicePaidCap" is not null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is not null and stg."MemberServicePaidCap" != pb."MemberServicePaidCap")
            OR (stg."CoverageVisitLimit" is null AND pb."CoverageVisitLimit" is not null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is not null and stg."CoverageVisitLimit" != pb."CoverageVisitLimit")
            OR (stg."FirstDollarVisits" is null AND pb."FirstDollarVisits" is not null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is not null and stg."FirstDollarVisits" != pb."FirstDollarVisits")
            OR (stg."IsGrouped" is null AND pb."IsGrouped" is not null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is not null and stg."IsGrouped" != pb."IsGrouped")
            OR (stg."CopayAfterFirstVisits" is null AND pb."CopayAfterFirstVisits" is not null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is not null and stg."CopayAfterFirstVisits" != pb."CopayAfterFirstVisits")            
            );

    -- Insert new plans
    INSERT INTO
            "PlanBenefits"
            (
                "Year"
                ,"HiosPlanID"
                ,"Benefit"
                ,"ServiceNotCovered"
                ,"AppliesToDeductible"
                ,"Coinsurance"
                ,"CopayAmount"
                ,"CopayDayLimit"
                ,"CoinsuranceCopayOrder"
                ,"MemberServicePaidCap"
                ,"CoverageVisitLimit"
                ,"Notes"
                ,"Status"
                ,"FirstDollarVisits"
                ,"IsGrouped"
                ,"CopayAfterFirstVisits"
                ,"CreatedDate"
                ,"UpdatedDate"
            )
    SELECT       stg."Year"
                ,stg."HiosPlanID"
                ,stg."Benefit"
                ,stg."ServiceNotCovered"
                ,stg."AppliesToDeductible"
                ,stg."Coinsurance"
                ,stg."CopayAmount"
                ,stg."CopayDayLimit"
                ,stg."CoinsuranceCopayOrder"
                ,stg."MemberServicePaidCap"
                ,stg."CoverageVisitLimit"
                ,stg."Notes"
                ,'Good' as "Status"
                ,stg."FirstDollarVisits"
                ,stg."IsGrouped"
                ,stg."CopayAfterFirstVisits"
                ,update_dt_time as "CreatedDate"
                ,update_dt_time as "UpdatedDate"
    FROM    public.vw_stage_planbenefits as stg
    WHERE   NOT EXISTS (SELECT  1
                        FROM    public."PlanBenefits" as pb 
                        WHERE   stg."Year"          = pb."Year"
                        AND     stg."HiosPlanID"    = pb."HiosPlanID"
                        AND     stg."Benefit"       = pb."Benefit")
    AND     stg."PlanBenefitID" < 0 -- Negative in here means new plans
    ;

    -- Find count after update
    rcnt:=
        (
            SELECT   count(*) 
            FROM     public.vw_stage_planbenefits as stg
            INNER 
            JOIN    public."PlanBenefits" as pb ON   pb."PlanBenefitID" = stg."PlanBenefitID"
                                                AND  stg."Year" = pb."Year"
                                                AND  stg."HiosPlanID" = pb."HiosPlanID"
            WHERE    0 = 1
            OR (stg."Benefit" is null AND pb."Benefit" is not null) OR (stg."Benefit" is not null AND pb."Benefit" is null) OR (stg."Benefit" is not null AND pb."Benefit" is not null and stg."Benefit" != pb."Benefit")
            OR (stg."ServiceNotCovered" is null AND pb."ServiceNotCovered" is not null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is null) OR (stg."ServiceNotCovered" is not null AND pb."ServiceNotCovered" is not null and stg."ServiceNotCovered" != pb."ServiceNotCovered")
            OR (stg."AppliesToDeductible" is null AND pb."AppliesToDeductible" is not null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is null) OR (stg."AppliesToDeductible" is not null AND pb."AppliesToDeductible" is not null and stg."AppliesToDeductible" != pb."AppliesToDeductible")
            OR (stg."Coinsurance" is null AND pb."Coinsurance" is not null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is null) OR (stg."Coinsurance" is not null AND pb."Coinsurance" is not null and stg."Coinsurance" != pb."Coinsurance")
            OR (stg."CopayAmount" is null AND pb."CopayAmount" is not null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is null) OR (stg."CopayAmount" is not null AND pb."CopayAmount" is not null and stg."CopayAmount" != pb."CopayAmount")
            OR (stg."CopayDayLimit" is null AND pb."CopayDayLimit" is not null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is null) OR (stg."CopayDayLimit" is not null AND pb."CopayDayLimit" is not null and stg."CopayDayLimit" != pb."CopayDayLimit")
            OR (stg."CoinsuranceCopayOrder" is null AND pb."CoinsuranceCopayOrder" is not null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is null) OR (stg."CoinsuranceCopayOrder" is not null AND pb."CoinsuranceCopayOrder" is not null and stg."CoinsuranceCopayOrder" != pb."CoinsuranceCopayOrder")
            OR (stg."MemberServicePaidCap" is null AND pb."MemberServicePaidCap" is not null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is null) OR (stg."MemberServicePaidCap" is not null AND pb."MemberServicePaidCap" is not null and stg."MemberServicePaidCap" != pb."MemberServicePaidCap")
            OR (stg."CoverageVisitLimit" is null AND pb."CoverageVisitLimit" is not null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is null) OR (stg."CoverageVisitLimit" is not null AND pb."CoverageVisitLimit" is not null and stg."CoverageVisitLimit" != pb."CoverageVisitLimit")
            OR (stg."FirstDollarVisits" is null AND pb."FirstDollarVisits" is not null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is null) OR (stg."FirstDollarVisits" is not null AND pb."FirstDollarVisits" is not null and stg."FirstDollarVisits" != pb."FirstDollarVisits")
            OR (stg."IsGrouped" is null AND pb."IsGrouped" is not null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is null) OR (stg."IsGrouped" is not null AND pb."IsGrouped" is not null and stg."IsGrouped" != pb."IsGrouped")
            OR (stg."CopayAfterFirstVisits" is null AND pb."CopayAfterFirstVisits" is not null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is null) OR (stg."CopayAfterFirstVisits" is not null AND pb."CopayAfterFirstVisits" is not null and stg."CopayAfterFirstVisits" != pb."CopayAfterFirstVisits")
        );
    raise notice 'Count After Update, Should be Zero : %',rcnt;
    raise notice 'Rows Updated or Inserted at: %', update_dt_time;

END;
$$;