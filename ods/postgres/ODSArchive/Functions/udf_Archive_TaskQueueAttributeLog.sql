-- udf_Archive_TaskQueueAttributeLog
DROP FUNCTION IF EXISTS arch."udf_Archive_TaskQueueAttributeLog"(jsonb);
CREATE OR REPLACE FUNCTION arch."udf_Archive_TaskQueueAttributeLog"(TaskAttributes jsonb)
RETURNS 
    SETOF INT AS $$
DECLARE
    retRecord arch."TaskQueueAttributeLogArchive"%rowtype;
    archiveTime TIMESTAMP default CURRENT_TIMESTAMP;
BEGIN
    IF TaskAttributes IS NOT NULL THEN
        INSERT INTO arch."TaskQueueAttributeLogArchive" AS A
            (
                 "ArchiveDtTm"
                ,"TaskQueueAttributeLogId"
                ,"DataPipeLineTaskQueueId"
                ,"AttributeName"
                ,"AttributeValue"
                ,"CreatedDtTm"
                ,"UpdatedDtTm"
            )
        SELECT   archiveTime as "ArchiveDtTm"
                ,CAST(CAST(value->'TaskQueueAttributeLogId' AS VARCHAR(20)) AS INT) AS "TaskQueueAttributeLogId"
                ,CAST(CAST(value->'DataPipeLineTaskQueueId' AS VARCHAR(20)) AS INT) AS "DataPipeLineTaskQueueId"
                ,REPLACE(CAST(value->'AttributeName' AS VARCHAR(60)), '"', '') AS "AttributeName"
                ,REPLACE(CAST(value->'AttributeValue' AS VARCHAR(500)), '"', '') AS "AttributeValue"
                ,CAST(CAST(value->'CreatedDtTm' AS VARCHAR(40)) AS TIMESTAMP) AS "CreatedDtTm"
                ,CAST(CAST(value->'UpdatedDtTm' AS VARCHAR(40)) AS TIMESTAMP) AS "UpdatedDtTm"
        FROM    jsonb_array_elements(TaskAttributes)
        ON  CONFLICT ON CONSTRAINT UNQ_TaskQueueAttributeLogArchive
        DO  UPDATE
            SET  "ArchiveDtTm" = EXCLUDED."ArchiveDtTm"
                ,"DataPipeLineTaskQueueId" = EXCLUDED."DataPipeLineTaskQueueId"
                ,"AttributeName" = EXCLUDED."AttributeName"
                ,"AttributeValue" = EXCLUDED."AttributeValue"
                ,"CreatedDtTm" = EXCLUDED."CreatedDtTm"
                ,"UpdatedDtTm" = EXCLUDED."UpdatedDtTm";
    END IF;

    -- Result
    FOR retRecord in 
        SELECT  "ArchiveId"
        FROM    arch."TaskQueueAttributeLogArchive" A
        INNER
        JOIN    (
                    SELECT  CAST(CAST(value->'TaskQueueAttributeLogId' as VARCHAR(40)) AS INT) as "TaskQueueAttributeLogId"
                    FROM    jsonb_array_elements(TaskAttributes)
                ) AS T ON   T."TaskQueueAttributeLogId" = A."TaskQueueAttributeLogId"
    LOOP
        return next retRecord."ArchiveId";
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    -- Code to test and verify
    SELECT arch."udf_Archive_TaskQueueAttributeLog"('[{"TaskQueueAttributeLogId":143364,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.0.JsonObjectName","AttributeValue":"enrollments","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143365,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.0.JsonSchemaPath","AttributeValue":"enrollments","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143366,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.1.JsonObjectName","AttributeValue":"Cart","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143367,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.1.JsonSchemaPath","AttributeValue":"enrollments.Cart","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143368,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.2.JsonObjectName","AttributeValue":"NotIncluded","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143369,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.2.JsonSchemaPath","AttributeValue":"enrollments.Cart.NotIncluded","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143370,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.3.JsonObjectName","AttributeValue":"Benefits","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143371,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.3.JsonSchemaPath","AttributeValue":"enrollments.Cart.Benefits","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143372,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.4.JsonObjectName","AttributeValue":"Math","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143373,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.4.JsonSchemaPath","AttributeValue":"enrollments.Cart.Benefits.Math","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143374,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.5.JsonObjectName","AttributeValue":"Formulas","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143375,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.5.JsonSchemaPath","AttributeValue":"enrollments.Cart.Benefits.Math.Formulas","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143376,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.6.JsonObjectName","AttributeValue":"Family","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143377,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.6.JsonSchemaPath","AttributeValue":"enrollments.Cart.Benefits.Math.Family","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143378,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.7.JsonObjectName","AttributeValue":"MonthlyRates","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143379,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.7.JsonSchemaPath","AttributeValue":"enrollments.Cart.Benefits.Math.Family.MonthlyRates","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143380,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.8.JsonObjectName","AttributeValue":"Persons","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143381,"DataPipeLineTaskQueueId":948,"AttributeName":"Flat.8.JsonSchemaPath","AttributeValue":"enrollments.Cart.Benefits.Persons","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143232,"DataPipeLineTaskQueueId":948,"AttributeName":"LogLevel","AttributeValue":"info","CreatedDtTm":"2018-12-14T19:18:17.758553","UpdatedDtTm":"2018-12-14T19:18:17.758553"}, 
 {"TaskQueueAttributeLogId":3861,"DataPipeLineTaskQueueId":948,"AttributeName":"Prefix.FlatJSONFile","AttributeValue":"dynamodb/enrollments/945/946-948-enrollments-FlatJSON-","CreatedDtTm":"2018-09-13T19:55:21.959271","UpdatedDtTm":"2018-09-13T19:55:21.959271"}, 
 {"TaskQueueAttributeLogId":3858,"DataPipeLineTaskQueueId":948,"AttributeName":"Prefix.UniformJSONFile","AttributeValue":"dynamodb/enrollments/945/946-948-enrollments-UniformJSON-","CreatedDtTm":"2018-09-13T19:55:21.959271","UpdatedDtTm":"2018-09-13T19:55:21.959271"}, 
 {"TaskQueueAttributeLogId":3849,"DataPipeLineTaskQueueId":948,"AttributeName":"PreviousTaskId","AttributeValue":"947","CreatedDtTm":"2018-09-13T19:55:21.959271","UpdatedDtTm":"2018-09-13T19:55:21.959271"}, 
 {"TaskQueueAttributeLogId":3859,"DataPipeLineTaskQueueId":948,"AttributeName":"S3DataFile","AttributeValue":"https://s3-us-west-2.amazonaws.com/dev-ods-data/dynamodb/enrollments/945/945-enrollments-Data-20180913_195521727.json","CreatedDtTm":"2018-09-13T19:55:21.959271","UpdatedDtTm":"2018-09-13T19:55:21.959271"}, 
 {"TaskQueueAttributeLogId":143361,"DataPipeLineTaskQueueId":948,"AttributeName":"S3FlatJsonFile","AttributeValue":"s3://dev-ods-data/dynamodb/enrollments/945/946-948-enrollments-FlatJSON-20181214_191819572.json","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}, 
 {"TaskQueueAttributeLogId":143230,"DataPipeLineTaskQueueId":948,"AttributeName":"S3SchemaFile","AttributeValue":"s3://dev-ods-data/dynamodb/enrollments/945/946-947-enrollments-Schema-20181214_191817487.json","CreatedDtTm":"2018-12-14T19:18:17.758553","UpdatedDtTm":"2018-12-14T19:18:17.758553"}, 
 {"TaskQueueAttributeLogId":3860,"DataPipeLineTaskQueueId":948,"AttributeName":"S3UniformJSONBucketName","AttributeValue":"dev-ods-data","CreatedDtTm":"2018-09-13T19:55:21.959271","UpdatedDtTm":"2018-09-13T19:55:21.959271"}, 
 {"TaskQueueAttributeLogId":143362,"DataPipeLineTaskQueueId":948,"AttributeName":"S3UniformJSONFile","AttributeValue":"s3://dev-ods-data/dynamodb/enrollments/945/946-948-enrollments-UniformJSON-20181214_191818948.json","CreatedDtTm":"2018-12-14T19:18:19.702033","UpdatedDtTm":"2018-12-14T19:18:19.702033"}]'::jsonb);
*/