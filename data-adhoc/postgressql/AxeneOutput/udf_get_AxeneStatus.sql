DROP FUNCTION public.udf_get_AxeneStatus(int, varchar(20), VARCHAR(40));
DROP TYPE IF EXISTS public.AxeneStatusReturnType;
CREATE TYPE public.AxeneStatusReturnType as (
     "BatchId"                  INT
    ,"Year"                     INT
    ,"State"                    VARCHAR(255)
    ,"PlanId"                   VARCHAR(255)
    ,"NumberOfPlansSubmitted"   INT
    ,"NumberOfPlansReceived"    INT
    ,"Status"                   VARCHAR(30) -- (Completed, Running, Ready to Run/Re-Run, Completed with Errors)
    ,"NumberOfPlansWithAV"      INT
    ,"NumberOfPlansWithErrors"  INT
    ,"LastSubmissionTime"       TIMESTAMP
    ,"LastSubmissionEndTime"    TIMESTAMP
    ,"AllowNewRun"              BOOLEAN
    ,"RunMode"                  VARCHAR(30) -- (Single Plan, State, Carier(for future))
);

CREATE OR REPLACE FUNCTION public.udf_get_AxeneStatus(Year int, State VARCHAR(20) default null, PlanId VARCHAR(40) default null) 
RETURNS 
    SETOF public.AxeneStatusReturnType AS $$
DECLARE
    retRecord public.AxeneStatusReturnType%rowtype;
    sql_code VARCHAR;
    BatchIDs VARCHAR(1000);
BEGIN

    State := COALESCE(State, '');
    PlanId := COALESCE(PlanId, '');

    IF Year is null THEN
        Year := date_part('year', CURRENT_DATE);
    END IF;

    SELECT  string_agg(CAST(AB."ID" AS VARCHAR), ',')
    INTO    BatchIDs
    FROM    "AxeneBatch" AS AB 
    WHERE   1 = 1
    AND     (
                (("Event"->'query'->>'Year' = CAST(Year AS VARCHAR)) AND (Year IS NOT NULL))
            )
    AND     (
                (("Event"->'query'->>'State' = State) AND (LENGTH(State) > 0))
                OR
                (
                    ((LENGTH(PlanID) > 0) AND ("Event"->'query'->>'State' IS NULL))
                    OR
                    ((LENGTH(State) = 0) AND ("Event"->'query'->>'State' IS NOT NULL))
                )
            )
    AND     (
                (("Event"->'query'->>'PlanID' = PlanId) AND (LENGTH(PlanID) > 0))
                OR
                ((LENGTH(PlanID) = 0) AND ("Event"->'query'->>'PlanID' IS NULL))
            );

    IF BatchIDs IS NULL THEN
        SELECT  string_agg(CAST(AB."ID" AS VARCHAR), ',')
        INTO    BatchIDs
        FROM    "AxeneBatch" AS AB 
        WHERE   1 = 1
        AND     (
                    (("Event"->'body'->>'Year' = CAST(Year AS VARCHAR)) AND (Year IS NOT NULL))
                )
        AND     (
                    (("Event"->'body'->>'State' = State) AND (LENGTH(State) > 0))
                    OR
                    (
                        ((LENGTH(PlanID) > 0) AND ("Event"->'body'->>'State' IS NULL))
                        OR
                        ((LENGTH(State) = 0) AND ("Event"->'body'->>'State' IS NOT NULL))
                    )
                )
        AND     (
                    (("Event"->'body'->>'PlanID' = PlanId) AND (LENGTH(PlanID) > 0))
                    OR
                    ((LENGTH(PlanID) = 0) AND ("Event"->'body'->>'PlanID' IS NULL))
                );
    END IF;

    BatchIDs := COALESCE(BatchIDs, '-1');
    raise notice '%',BatchIDs;

    sql_code := '    
        WITH AxeneBatchStatus
        AS
        (
            SELECT   AB."ID"
                ,COALESCE("Event"->''query''->>''Year'', "Event"->''body''->>''Year'')   AS "Year"
                ,COALESCE("Event"->''query''->>''State'', "Event"->''body''->>''State'')  AS "State"
                ,COALESCE("Event"->''query''->>''PlanID'', "Event"->''body''->>''PlanID'') AS "PlanId"
                ,COUNT(*) AS "NumberOfPlansSubmitted"
                ,SUM(CASE WHEN "EndDate" IS NOT NULL THEN 1 ELSE 0 END) as "NumberOfPlansReceived"
                ,(SELECT COUNT(*) FROM "AxeneOutputValues" AS AO WHERE AO."BatchID" = CAST(AB."ID" AS VARCHAR)) as "NumberOfPlansWithAV"
                ,SUM(CASE WHEN "Status" = ''error'' THEN 1 ELSE 0 END) as "NumberOfPlansWithErrors"
                ,MIN("StartDate") as "LastSubmissionTime"
                ,MAX("EndDate") as "LastSubmissionEndTime"
                ,ROW_NUMBER() OVER (PARTITION BY 
                                     COALESCE("Event"->''query''->>''Year'', "Event"->''body''->>''Year'')
                                    ,COALESCE("Event"->''query''->>''PlanID'', "Event"->''body''->>''PlanID'')
                                    ,COALESCE("Event"->''query''->>''State'', "Event"->''body''->>''State'')
                                    ORDER BY MIN(AF1."StartDate") DESC) as RowNbr
            FROM    "AxeneBatch" AS AB 
            INNER
            JOIN    "AxeneBatchFiles" AS AF1 ON AF1."AxeneBatchID" = AB."ID"
            WHERE   1 = 1
            AND     AB."ID" IN (' || BatchIDs || ')
            GROUP   BY
                AB."ID"
                ,COALESCE("Event"->''query''->>''Year'', "Event"->''body''->>''Year'')
                ,COALESCE("Event"->''query''->>''State'', "Event"->''body''->>''State'')
                ,COALESCE("Event"->''query''->>''PlanID'', "Event"->''body''->>''PlanID'')

            UNION

            SELECT  DISTINCT
                -1 as "ID"
                ,CAST("Year" as VARCHAR) as "Year"
                ,"State"
                ,CAST(null as VARCHAR) as "PlanId"
                ,CAST(0 as INT) AS "NumberOfPlansSubmitted"
                ,CAST(0 as INT) as "NumberOfPlansReceived"
                ,CAST(0 as INT) as "NumberOfPlansWithAV"
                ,CAST(0 as INT) as "NumberOfPlansWithErrors"
                ,CAST(null as TIMESTAMP) as "LastSubmissionTime"
                ,CAST(null as TIMESTAMP) as "LastSubmissionEndTime"
                ,1 as RowNbr
            FROM    "Plans"
            WHERE   "Year" = ' || CAST(Year as VARCHAR) || '
            AND     LENGTH(''' || State || ''') = 0
            AND     LENGTH(''' || PlanID || ''') = 0
            AND     "State" NOT IN 
                    (
                        SELECT  DISTINCT COALESCE("Event"->''query''->>''State'', "Event"->''body''->>''State'')
                        FROM    "AxeneBatch" AB
                        WHERE   AB."ID" IN (' || BatchIDs || ')
                        AND     COALESCE("Event"->''query''->>''State'', "Event"->''body''->>''State'') IS NOT NULL
                    )
        )
        SELECT   "ID" as "BatchID"
                ,"Year"
                ,"State"
                ,"PlanId"
                ,"NumberOfPlansSubmitted"
                ,"NumberOfPlansReceived"
                ,CASE 
                    WHEN "NumberOfPlansSubmitted" = "NumberOfPlansWithAV" THEN ''Completed''
                    WHEN ("NumberOfPlansSubmitted" = "NumberOfPlansReceived") AND ("NumberOfPlansWithErrors" > 0) THEN ''Completed with Errors''
                    WHEN ("NumberOfPlansSubmitted" = "NumberOfPlansReceived") AND ("NumberOfPlansWithAV" != "NumberOfPlansSubmitted") THEN ''Completed with Errors''
                    WHEN "NumberOfPlansSubmitted" = "NumberOfPlansReceived" THEN ''Completed'' 
                    ELSE ''Running'' 
                END AS "Status"
                ,"NumberOfPlansWithAV"
                ,"NumberOfPlansWithErrors"
                ,"LastSubmissionTime"
                ,"LastSubmissionEndTime"
                ,CASE 
                    WHEN "NumberOfPlansSubmitted" = "NumberOfPlansWithAV" THEN TRUE
                    WHEN ("NumberOfPlansSubmitted" = "NumberOfPlansReceived") AND ("NumberOfPlansWithErrors" > 0) THEN TRUE
                    WHEN ("NumberOfPlansSubmitted" = "NumberOfPlansReceived") AND ("NumberOfPlansWithAV" != "NumberOfPlansSubmitted") THEN TRUE
                    WHEN "NumberOfPlansSubmitted" = "NumberOfPlansReceived" THEN TRUE
                    ELSE FALSE
                END AS "AllowNewRun"
                ,CASE WHEN "PlanId" IS NOT NULL THEN ''SinglePlan'' 
                    WHEN "State" IS NOT NULL THEN ''State'' 
                    ELSE ''Batch'' END AS "RunMode"
        FROM    AxeneBatchStatus
        WHERE   RowNbr = 1
    ;';
    raise notice '%',sql_code;
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

/*
    -- Testing Code
    -- Returns status for All states
    SELECT * FROM public.udf_get_AxeneStatus(2018, '', '');
    -- Returns status for only California
    SELECT * FROM public.udf_get_AxeneStatus(2018, 'CA', '');
    -- Returns only single plan
    SELECT * FROM public.udf_get_AxeneStatus(2018, '', '11150ce1-18ea-483b-9628-bc5e239ec4ed');
*/