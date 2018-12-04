DROP FUNCTION IF EXISTS public."udf_ParseMergeParams"(jsonb);
CREATE OR REPLACE FUNCTION public."udf_ParseMergeParams"(MergeParams jsonb)
RETURNS TABLE 
(
     "StgTableSchema" VARCHAR(256)
    ,"StgTableName" VARCHAR(256)
    ,"ParentStgTableName" VARCHAR(256)
    ,"CleanTableSchema" VARCHAR(256)
    ,"CleanTableName" VARCHAR(256)
    ,"CleanParentTableName" VARCHAR(256)
    ,"PrimaryKeyName" VARCHAR(256)
    ,"BusinessKeyColumn" VARCHAR(256)
    ,"RootTableName" VARCHAR(256)
    ,"PreStageToStageTaskId" BIGINT 
    ,"TaskQueueId" BIGINT
    ,"HasRoot" BOOLEAN
    ,"HasParent" BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE 
    sql_code text;
BEGIN

    sql_code := 'WITH CTEParams
    AS
    (
    SELECT
         CAST(param->''StageTable''->>''Schema'' AS VARCHAR(256)) as "StageTableSchema"
        ,CAST(param->''StageTable''->>''TableName'' AS VARCHAR(256)) as "StageTableName"
        ,CAST(param->''StageTable''->>''ParentTableName'' AS VARCHAR(256)) as "StageParentTableName"
        ,CAST(param->''CleanTable''->>''Schema'' AS VARCHAR(256)) as "CleanTblSchema"
        ,CAST(param->''CleanTable''->>''TableName'' AS VARCHAR(256)) as "CleanTblName"
        ,CAST(param->''CleanTable''->>''ParentTableName'' AS VARCHAR(256)) as "CleanParentTblName"
        ,CAST(param->''CleanTable''->>''PrimaryKeyName'' AS VARCHAR(256)) as "PKName"
        ,CAST(param->''CleanTable''->>''BusinessKeyColumn'' AS VARCHAR(256)) as "BizKeyName"
        ,CAST(param->''CleanTable''->>''RootTableName'' AS VARCHAR(256)) as "RootTblName"
        ,CAST(param->''PreStageToStageTaskId'' AS VARCHAR) as "PreStgToStgTaskId"
        ,CAST(param->''TaskQueueId'' AS VARCHAR) as "TaskQId"
    FROM (SELECT $1 as param) as p
    )
    SELECT   "StageTableSchema"
            ,"StageTableName"
            ,COALESCE("StageParentTableName", '''') as "ParentStgTableName"
            ,"CleanTblSchema"
            ,"CleanTblName"
            ,COALESCE("CleanParentTblName", '''') as "CleanParentTableName"
            ,COALESCE("PKName", '''') as "PrimaryKeyName"
            ,COALESCE("BizKeyName", '''') as "BusinessKeyColumn"
            ,COALESCE("RootTblName", '''') as "RootTableName"
            ,CAST("PreStgToStgTaskId" as BIGINT) as "PreStageToStageTaskId"
            ,CAST("TaskQId" as BIGINT) as "TaskQueueId"
            ,CASE WHEN LENGTH("RootTblName") > 0 THEN TRUE ELSE FALSE END AS "HasRoot"
            ,CASE WHEN LENGTH("CleanParentTblName") > 0 THEN TRUE ELSE FALSE END AS "HasParent"
    FROM    CTEParams;';
    RETURN QUERY EXECUTE sql_code USING MergeParams;

END;
$$;
GRANT ALL on FUNCTION public."udf_ParseMergeParams"(jsonb) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_ParseMergeParams"(jsonb) TO public;

/*
    -- Testing code
    SELECT * FROM  public."udf_ParseMergeParams"('{"StageTable" : {
         "Schema": "stg",
         "TableName": "clients_clients",
         "ParentTableName": ""
         },
         "CleanTable" : {
            "Schema": "public",
            "TableName": "clients_clients",
            "ParentTableName": "",
            "PrimaryKeyName": "",
            "BusinessKeyColumn": "",
            "RootTableName": ""
          },
          "PreStageToStageTaskId": 1,
          "TaskQueueId": 2}'::jsonb);
*/
