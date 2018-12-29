-- udf_Archive_DataPipeLineTaskQueue
DROP FUNCTION IF EXISTS arch."udf_Archive_DataPipeLineTaskQueue"(jsonb);
CREATE OR REPLACE FUNCTION arch."udf_Archive_DataPipeLineTaskQueue"(Tasks jsonb)
RETURNS 
    SETOF INT AS $$
DECLARE
    retRecord arch."DataPipeLineTaskQueueArchive"%rowtype;
    archiveTime TIMESTAMP default CURRENT_TIMESTAMP;
BEGIN
    IF Tasks IS NOT NULL THEN
        INSERT INTO arch."DataPipeLineTaskQueueArchive" AS A
            (
                 "ArchiveDtTm"
                ,"DataPipeLineTaskQueueId"
                ,"DataPipeLineTaskId"
                ,"ParentTaskId"
                ,"RunSequence"
                ,"TaskStatusId"
                ,"StartDtTm"
                ,"EndDtTm"
                ,"Error"
                ,"CreatedDtTm"
                ,"UpdatedDtTm"
            )
        SELECT   archiveTime as "ArchiveDtTm"
                ,CAST(CAST(value->'DataPipeLineTaskQueueId' as VARCHAR(40)) AS INT) as "DataPipeLineTaskQueueId"
                ,CAST(CAST(value->'DataPipeLineTaskId' as VARCHAR(40)) AS INT) as "DataPipeLineTaskId"
                ,CASE WHEN CAST(value->'ParentTaskId' as VARCHAR(40)) = 'null' 
                    THEN null 
                    ELSE CAST(CAST(value->'ParentTaskId' as VARCHAR(40)) AS INT) 
                 END as "ParentTaskId"
                ,CAST(CAST(value->'RunSequence' as VARCHAR(40)) AS INT) as "RunSequence"
                ,CAST(CAST(value->'TaskStatusId' as VARCHAR(40)) AS INT) as "TaskStatusId"
                ,CAST(CAST(value->'StartDtTm' as VARCHAR(40)) AS TIMESTAMP) as "StartDtTm"
                ,CAST(CAST(value->'EndDtTm' as VARCHAR(40)) AS TIMESTAMP) as "EndDtTm"
                ,CASE WHEN CAST(value->'Error' as TEXT) = 'null' 
                    THEN CAST(null as jsonb)
                    ELSE value->'Error' 
                 END as "Error"
                ,CAST(CAST(value->'CreatedDtTm' as VARCHAR(40)) AS TIMESTAMP) as "CreatedDtTm"
                ,CAST(CAST(value->'UpdatedDtTm' as VARCHAR(40)) AS TIMESTAMP) as "UpdatedDtTm"
        FROM    jsonb_array_elements(Tasks)
        ON  CONFLICT ON CONSTRAINT UNQ_DataPipeLineTaskQueueArchive
        DO  UPDATE
            SET  "ArchiveDtTm" = EXCLUDED."ArchiveDtTm"
                ,"DataPipeLineTaskId" = EXCLUDED."DataPipeLineTaskId"
                ,"ParentTaskId"       = EXCLUDED."ParentTaskId"
                ,"RunSequence"        = EXCLUDED."RunSequence"
                ,"TaskStatusId"       = EXCLUDED."TaskStatusId"
                ,"StartDtTm"          = EXCLUDED."StartDtTm"
                ,"EndDtTm"            = EXCLUDED."EndDtTm"
                ,"Error"              = EXCLUDED."Error"
                ,"CreatedDtTm"        = EXCLUDED."CreatedDtTm"
                ,"UpdatedDtTm"        = EXCLUDED."UpdatedDtTm";
    END IF;

    -- Result
    FOR retRecord in 
        SELECT  "ArchiveId"
        FROM    arch."DataPipeLineTaskQueueArchive"
        WHERE   "DataPipeLineTaskQueueId" IN 
                (
                    SELECT  CAST(CAST(value->'DataPipeLineTaskQueueId' as VARCHAR(40)) AS INT) as "DataPipeLineTaskQueueId"
                    FROM    jsonb_array_elements(Tasks)
                )
    LOOP
        return next retRecord."ArchiveId";
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    -- Code to test and verify
    SELECT arch."udf_Archive_DataPipeLineTaskQueue"('[{"DataPipeLineTaskQueueId":948,"DataPipeLineTaskId":730
    ,"ParentTaskId":946,"RunSequence":2020,"TaskStatusId":50
    ,"StartDtTm":"2018-12-14T19:18:17.815409","EndDtTm":"2018-12-14T19:18:19.702033"
    ,"Error":{},"CreatedDtTm":"2018-09-13T19:55:21.959271"
    ,"UpdatedDtTm":"2018-12-14T19:18:19.702033"}]'::jsonb);
*/