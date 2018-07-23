DROP FUNCTION public.udf_get_AxeneStatus(int, varchar(255));
DROP TYPE IF EXISTS public.AxeneBatchStatusReturnType;
CREATE TYPE public.AxeneBatchStatusReturnType as (
     "ID"                   INT
    ,"Year"                 INT
    ,"State"                VARCHAR(255)
    ,"PlanId"               VARCHAR(255)
    ,"SinglePlan"           BOOLEAN
    ,"BatchCompleted"       BOOLEAN
    ,"InputFileCount"       INT
    ,"CompletedFileCount"   INT
    ,"OutputFileCount"      INT
    ,"StartDate"            TIMESTAMP
    ,"EndDate"              TIMESTAMP
);

CREATE OR REPLACE FUNCTION public.udf_get_AxeneStatus(Duration int, DurationType VARCHAR(255)) 
RETURNS 
    SETOF public.AxeneBatchStatusReturnType AS $$
DECLARE
    retRecord public.AxeneBatchStatusReturnType%rowtype;
    sql_code VARCHAR;
    IntervalProvided VARCHAR;
BEGIN

    IF DurationType NOT IN ('second', 'minute', 'hour', 'day', 'week', 'month', 'days', 'minutes') THEN
        DurationType := 'minute';
    END IF;

    IF Duration <= 0 THEN
        Duration := 30;
    END IF;

    IntervalProvided := CAST(Duration as VARCHAR(3)) || ' ' || DurationType;

    sql_code := ';WITH AxeneBatchStatus
    AS
    (
        SELECT   AB."ID"
                ,AB."Event"
                ,COUNT(*) AS "InputFileCount"
                ,SUM (CASE WHEN AF1."EndDate" IS NULL THEN 0 ELSE 1 END) AS "CompletedFileCount"
                ,(SELECT COUNT(*) FROM "AxeneOutputValues" AS AO WHERE AO."BatchID" = CAST(AB."ID" AS VARCHAR)) as "OutputFileCount"
                ,MIN(AF1."StartDate") AS "StartDate"
                ,MIN(AF1."EndDate") AS "EndDate"
                ,ROW_NUMBER() OVER (PARTITION BY "Event"->''query''->>''Year''
                                    , "Event"->''query''->>''PlanId''
                                    , "Event"->''query''->>''State'' ORDER BY MIN(AF1."StartDate") DESC) as RowNbr
        FROM    "AxeneBatch" AS AB 
        INNER
        JOIN    "AxeneBatchFiles" AS AF1 ON AF1."AxeneBatchID" = AB."ID"
        WHERE   EXISTS
                (
                    SELECT  DISTINCT "AxeneBatchID"
                    FROM    "AxeneBatchFiles" AS AF
                    WHERE   (
                                ((AF."EndDate" IS NULL) AND (AF."StartDate" >= NOW() - interval ''' || IntervalProvided || ''' ))
                            OR  ((AF."EndDate" IS NOT NULL) AND (AF."EndDate" >= NOW() - interval ''' || IntervalProvided || ''' ))
                            )
                    AND     AF."AxeneBatchID" = AB."ID"
                )
        GROUP   BY
                AB."ID"
                ,AB."Event"
    )
    SELECT   "ID"
            ,"Event"->''query''->>''Year'' as "Year"
            ,"Event"->''query''->>''State'' as "State"
            ,"Event"->''query''->>''PlanId'' as "PlanId"
            ,CASE WHEN "Event"->''query''->>''PlanId'' IS NOT NULL THEN TRUE ELSE FALSE END AS "SinglePlan"
            ,CASE WHEN "InputFileCount" = "CompletedFileCount" THEN TRUE ELSE FALSE END AS "BatchCompleted"
            ,"InputFileCount"
            ,"CompletedFileCount"
            ,"OutputFileCount"
            ,"StartDate"
            ,"EndDate"
    FROM    AxeneBatchStatus
    WHERE   RowNbr = 1
    ;';
    -- raise notice '%',sql_code;
    execute sql_code;

    -- Result
    FOR retRecord in execute sql_code
    LOOP
        -- raise notice '%',retRecord;
        return next retRecord;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;