-- udf_GetPipeLineTask_Archive
DROP FUNCTION IF EXISTS ods."udf_GetPipeLineTask_Archive"(jsonb);
CREATE OR REPLACE FUNCTION ods."udf_GetPipeLineTask_Archive"(TaskListJson jsonb) 
RETURNS 
    SETOF ods."DataPipeLineTaskQueue" AS $$
DECLARE
    sql_code TEXT;
BEGIN
    IF TaskListJson IS NULL THEN
        TaskListJson := '[{"ParentId":-1,"DataPipeLineTaskQueueId":-1,"CreatedDtTm":"2018-01-01"}]'::jsonb;
    END IF;

    sql_code := '
    SELECT  *
    FROM    ods."DataPipeLineTaskQueue" AS Q
    WHERE   "DataPipeLineTaskQueueId" IN (
                SELECT  CAST(CAST(jsonb_array_elements(S1::jsonb)->''DataPipeLineTaskQueueId'' AS VARCHAR(20)) AS INT)
                FROM    (SELECT $1 AS S1) T
            );';

    RETURN QUERY EXECUTE sql_code USING TaskListJson;
    
END;
$$ LANGUAGE plpgsql;
GRANT ALL ON FUNCTION ods."udf_GetPipeLineTask_Archive"(jsonb) TO odsconfig_user;

/*
    SELECT * 
    FROM ods."udf_GetPipeLineTask_Archive"('[{"ParentId":946,"DataPipeLineTaskQueueId":948,"CreatedDtTm":"2018-09-13T19:55:21.959271"}]'::jsonb);
*/
