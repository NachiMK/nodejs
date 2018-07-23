DROP FUNCTION public.udf_get_AxeneStatus(int, varchar(20), VARCHAR(40));
DROP TYPE IF EXISTS public.AxeneStatusReturnType;
CREATE TYPE public.AxeneStatusReturnType as (
     "BatchId"                  INT
    ,"Year"                     INT
    ,"State"                    VARCHAR(255)
    ,"PlanId"                   VARCHAR(255)
    ,"NumberofPlansSubmitted"   INT
    ,"NumberofPlansReceived"    INT
    ,"Status"                   VARCHAR(30) -- (Completed, Running, Ready to Run/Re-Run, Completed with Errors)
    ,"NumberofplanswithAV"      INT
    ,"NumberofPlanswithErrors"  INT
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

    SELECT  string_agg(CAST(AB."ID" AS VARCHAR), ',')
    INTO    BatchIDs
    FROM    "AxeneBatch" AS AB 
    WHERE   1 = 1
    AND     (
                (("Event"->'query'->>'Year' = CAST(Year AS VARCHAR)) AND (Year IS NOT NULL))
                OR
                (Year IS NULL)
            )
    AND     (
                (("Event"->'query'->>'State' = State) AND (State IS NOT NULL) AND (LENGTH(State) > 0))
                OR
                ((LENGTH(State) = 0) OR State IS NULL)
            )
    AND     (
                (("Event"->'query'->>'PlanID' = PlanId) AND (PlanId IS NOT NULL) AND (LENGTH(PlanID) > 0))
                OR
                ((LENGTH(PlanID) = 0) OR PlanId IS NULL)
            );

    BatchIDs := COALESCE(BatchIDs, '-1');
    raise notice '%',BatchIDs;

    sql_code := '    
        WITH AxeneBatchStatus
        AS
        (
            SELECT   AB."ID"
                ,"Event"->''query''->>''Year'' AS "Year"
                ,"Event"->''query''->>''State'' AS "State"
                ,"Event"->''query''->>''PlanID'' AS "PlanId"
                ,COUNT(*) AS "NumberofPlansSubmitted"
                ,SUM(CASE WHEN "EndDate" IS NOT NULL THEN 1 ELSE 0 END) as "NumberofPlansReceived"
                ,(SELECT COUNT(*) FROM "AxeneOutputValues" AS AO WHERE AO."BatchID" = CAST(AB."ID" AS VARCHAR)) as "NumberofplanswithAV"
                ,SUM(CASE WHEN "Status" = ''error'' THEN 1 ELSE 0 END) as "NumberofPlanswithErrors"
                ,MIN("StartDate") as "LastSubmissionTime"
                ,MAX("EndDate") as "LastSubmissionEndTime"
                ,ROW_NUMBER() OVER (PARTITION BY "Event"->''query''->>''Year''
                                    ,"Event"->''query''->>''PlanID''
                                    ,"Event"->''query''->>''State'' ORDER BY MIN(AF1."StartDate") DESC) as RowNbr
            FROM    "AxeneBatch" AS AB 
            INNER
            JOIN    "AxeneBatchFiles" AS AF1 ON AF1."AxeneBatchID" = AB."ID"
            WHERE   1 = 1
            AND     AB."ID" IN (' || BatchIDs || ')
            GROUP   BY
                AB."ID"
                ,"Event"->''query''->>''Year''
                ,"Event"->''query''->>''State''
                ,"Event"->''query''->>''PlanID''

            UNION

            SELECT  DISTINCT
                -1 as "ID"
                ,CAST("Year" as VARCHAR) as "Year"
                ,"State"
                ,CAST(null as VARCHAR) as "PlanId"
                ,CAST(0 as INT) AS "NumberofPlansSubmitted"
                ,CAST(0 as INT) as "NumberofPlansReceived"
                ,CAST(0 as INT) as "NumberofplanswithAV"
                ,CAST(0 as INT) as "NumberofPlanswithErrors"
                ,CAST(null as TIMESTAMP) as "LastSubmissionTime"
                ,CAST(null as TIMESTAMP) as "LastSubmissionEndTime"
                ,1 as RowNbr
            FROM    "Plans"
            WHERE   "Year" = ' || CAST(Year as VARCHAR) || '
            AND     LENGTH(''' || State || ''') = 0
            AND     "State" NOT IN 
                    (
                        SELECT  DISTINCT "Event"->''query''->>''State''
                        FROM    "AxeneBatch" AB
                        WHERE   AB."ID" IN (' || BatchIDs || ')
                        AND     "Event"->''query''->>''State'' IS NOT NULL
                    )
        )
        SELECT   "ID" as "BatchID"
                ,"Year"
                ,"State"
                ,"PlanId"
                ,"NumberofPlansSubmitted"
                ,"NumberofPlansReceived"
                ,CASE 
                    WHEN ("NumberofPlansSubmitted" = "NumberofPlansReceived") AND ("NumberofPlanswithErrors" > 0) THEN ''Completed with Errors''
                    WHEN ("NumberofPlansSubmitted" = "NumberofPlansReceived") AND ("NumberofplanswithAV" != "NumberofPlansSubmitted") THEN ''Completed with Errors''
                    WHEN "NumberofPlansSubmitted" = "NumberofPlansReceived" THEN ''Completed'' 
                    ELSE ''Running'' 
                END AS "Status"
                ,"NumberofplanswithAV"
                ,"NumberofPlanswithErrors"
                ,"LastSubmissionTime"
                ,"LastSubmissionEndTime"
                ,CASE 
                    WHEN ("NumberofPlansSubmitted" = "NumberofPlansReceived") AND ("NumberofPlanswithErrors" > 0) THEN TRUE
                    WHEN ("NumberofPlansSubmitted" = "NumberofPlansReceived") AND ("NumberofplanswithAV" != "NumberofPlansSubmitted") THEN TRUE
                    WHEN "NumberofPlansSubmitted" = "NumberofPlansReceived" THEN TRUE
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