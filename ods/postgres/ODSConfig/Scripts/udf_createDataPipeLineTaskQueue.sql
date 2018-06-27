-- DROP FUNCTION IF EXISTS public."udf_createDataPipeLineTaskQueue"(varchar(255), INT);
CREATE OR REPLACE FUNCTION public."udf_createDataPipeLineTaskQueue"(ConfigName VARCHAR(255), RowCnt INT) 
RETURNS 
    SETOF DynamoDBtoS3ReturnType AS $$
DECLARE
    retRecord DynamoDBtoS3ReturnType%rowtype;
    dataFilePrefix VARCHAR(200);
    S3DataFileBucketName VARCHAR(600);
INSERT INTO "public"."DataPipeLineTaskQueue" 
(
     "DataPipeLineTaskId"
    ,"ParentTaskId"
    ,"RunSequence"
    ,"TaskStatusId"
    ,"StartDtTm"
    ,"CreatedDtTm"
)
VALUES 
    (
        0, 0, 0, 0, 0, '', '', '', '', ''
    );