DROP FUNCTION IF EXISTS ods."udf_GetPendingPipeLineTables"(INT);
CREATE OR REPLACE FUNCTION ods."udf_GetPendingPipeLineTables"(MaxItems INT DEFAULT 5) 
RETURNS 
    SETOF VARCHAR(200) AS $$
    -- retRecord ods."DataPipeLineTaskConfig"%rowtype;
BEGIN
    IF MaxItems <= 0 OR MaxItems IS NULL OR MaxItems > 10 THEN
        MaxItems := 5;
    END IF;

    -- Result
    RETURN QUERY  
    SELECT  "SourceEntity"
    FROM    (
            SELECT  DPL."SourceEntity"
                    ,DPL."DataPipeLineTaskId", Q."DataPipeLineTaskQueueId", Q."CreatedDtTm"
                    ,ROW_NUMBER() OVER (PARTITION BY DPL."SourceEntity", DPL."DataPipeLineTaskId" ORDER BY Q."CreatedDtTm") AS "TblSeq"
            FROM    ods."DataPipeLineTask"  AS DPL
            INNER
            JOIN    ods."DataPipeLineTaskConfig"   DPC ON  DPC."DataPipeLineTaskConfigId" = DPL."DataPipeLineTaskConfigId"
            INNER
            JOIN    ods."DataPipeLineTaskQueue" AS Q    ON Q."DataPipeLineTaskId" = DPL."DataPipeLineTaskId"
            INNER
            JOIN    ods."TaskStatus"    AS T    ON T."TaskStatusId" = Q."TaskStatusId"
            WHERE   DPC."TaskName" = 'Process JSON to Postgres'
            AND     T."TaskStatusDesc" IN ('Ready')
            AND     DPL."DeletedFlag" = false
            AND     DPL."DataPipeLineTaskId" NOT IN 
                    (
                        SELECT  DISTINCT "DataPipeLineTaskId"
                        FROM    ods."DataPipeLineTaskQueue" AS Q
                        INNER
                        JOIN    ods."TaskStatus"    AS T    ON T."TaskStatusId" = Q."TaskStatusId"
                        WHERE   "TaskStatusDesc" IN ('Processing', 'Error')
                    )
        ) AS T
    WHERE   "TblSeq" = 1
    ORDER BY
            "CreatedDtTm" ASC
    LIMIT MaxItems;
    -- LOOP
    --     RETURN NEXT retRecord."SourceEntity";
    -- END LOOP;
    -- RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM ods."udf_GetPendingPipeLineTables"();
    SELECT * FROM ods."udf_GetPendingPipeLineTables"(3);
    SELECT * FROM ods."udf_GetPendingPipeLineTables"(5);
    SELECT * FROM ods."udf_GetPendingPipeLineTables"(10);
*/