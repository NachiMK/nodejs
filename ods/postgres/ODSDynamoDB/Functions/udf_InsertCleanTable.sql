-- udf_InsertCleanTable
DROP FUNCTION IF EXISTS public."udf_InsertCleanTable"(jsonb, boolean);
CREATE OR REPLACE FUNCTION public."udf_InsertCleanTable"(MergeParams jsonb, NoInsertPrintOnly boolean default false)
RETURNS TABLE (
     "StgId"    BIGINT
    ,"TableId"  BIGINT
) AS $$
DECLARE 
    sql_code text;
    InsertCols text;
    StageTableSchema VARCHAR(256);
    StageTableName VARCHAR(256);
    ParentStgTableName VARCHAR(256);
    CleanTableSchema VARCHAR(256);
    CleanTableName VARCHAR(256);
    CleanParentTableName VARCHAR(256);
    PrimaryKeyName VARCHAR(256);
    BusinessKeyColumn VARCHAR(256);
    RootTableName VARCHAR(256);
    PreStageToStageTaskId BIGINT;
    TaskQueueId BIGINT;

    IsRootTable BOOLEAN;

    RootColName VARCHAR(256);
    ParentColName VARCHAR(256);

    TargetCols TEXT;
    SourceCols TEXT;
    AdditionalTargetCols TEXT DEFAULT '';
    AdditionalSourceCols TEXT DEFAULT '';
    WHERECondition TEXT DEFAULT '';
    JoinCondition TEXT DEFAULT '';
BEGIN
    SELECT   "StgTableSchema"
            ,"StgTableName"
            ,"ParentStgTableName"
            ,"CleanTableSchema"
            ,"CleanTableName"
            ,"CleanParentTableName"
            ,"PrimaryKeyName"
            ,"BusinessKeyColumn"
            ,"RootTableName"
            ,"PreStageToStageTaskId"
            ,"TaskQueueId"
            ,CASE WHEN LENGTH("BusinessKeyColumn") > 0 THEN TRUE ELSE FALSE END AS IsRootTable
    INTO     StageTableSchema
            ,StageTableName
            ,ParentStgTableName
            ,CleanTableSchema
            ,CleanTableName
            ,CleanParentTableName
            ,PrimaryKeyName
            ,BusinessKeyColumn
            ,RootTableName
            ,PreStageToStageTaskId
            ,TaskQueueId
            ,IsRootTable
    FROM    public."udf_ParseMergeParams"(MergeParams);

    SELECT   STRING_AGG(CT."QuotedColumnName", ',') as targetCols
            ,STRING_AGG('ST.' || ST."QuotedColumnName", ',') as sourceCols
    INTO    TargetCols, SourceCols
    FROM    public."vwColumnDefinition" as CT
    INNER
    JOIN    public."vwColumnDefinition" as ST ON CT."ColumnName" = ST."ColumnName"
    WHERE   CT."TableSchema" = CleanTableSchema
    AND     ST."TableSchema" = StageTableSchema
    AND     CT."TableName"   = CleanTableName
    AND     ST."TableName"   = StageTableName
    AND     CT."ColumnName" !~ PrimaryKeyName
    AND     ((LENGTH(BusinessKeyColumn) > 0  AND CT."ColumnName" !~ BusinessKeyColumn) OR (LENGTH(BusinessKeyColumn) = 0))
    AND     CT."ColumnName" !~ 'DataPipeLineTaskQueueId';

    IF IsRootTable THEN
        -- If Root no Parent or Root is required.
        AdditionalTargetCols := ',"ODS_StgId","ODS_Parent_Id","ODS_Root_Id","ODS_EffectiveStartDate"' ||
                                ',"ODS_EffectiveEndDate","ODS_RowCreatedDtTm","ODS_RowDeleted"'||
                                ',"ODS_DataPipeLineTaskQueueId", "' || BusinessKeyColumn || '"' ;
        -- source columns
        AdditionalSourceCols := '
        , ST."StgId" as "ODS_StgId"
        , -1 as "ODS_Parent_Id"
        , -1 AS "ODS_Root_Id"
        , ST."HistoryCreated"::DATE as "ODS_EffectiveStartDate"
        , ''12/31/9999'' as "ODS_EffectiveEndDate"
        , CURRENT_TIMESTAMP AS "ODS_RowCreatedDtTm"
        , false as "ODS_RowDeleted"
        , ' || CAST(TaskQueueId as VARCHAR) || ' as "ODS_DataPipeLineTaskQueueId"
        , ST."' || BusinessKeyColumn || '" AS BusinessKeyColumn';

        WHERECondition := ' AND   NOT EXISTS (SELECT 1 FROM ' || CleanTableSchema ||'."' || CleanTableName || '" AS C' ||
                          ' WHERE C."'|| BusinessKeyColumn || '" = ST."'|| BusinessKeyColumn ||'" ' ||
                          ' AND   C."ODS_EffectiveStartDate" = ST."HistoryCreated"::date ' ||
                          ' AND   C."ODS_EffectiveEndDate" = ''12-31-9999'')';
    ELSE
        -- Find my Parent Column
        SELECT  column_name
        INTO    ParentColName
        FROM    INFORMATION_SCHEMA.COLUMNS
        WHERE   table_schema = CleanTableSchema
        AND     table_name   = CleanTableName
        AND     column_name ~ 'ODS_Parent_.*Id';

        -- find my Root Column from my parent.
        SELECT  column_name
        INTO    RootColName
        FROM    INFORMATION_SCHEMA.COLUMNS
        WHERE   table_schema = CleanTableSchema
        AND     table_name   = CleanTableName
        AND     column_name ~ 'ODS_Root_.*Id';

        -- update the Target col list for inserting
        AdditionalTargetCols := ',"ODS_StgId", "' ||ParentColName || '","' || RootColName || 
        '","ODS_RowCreatedDtTm","ODS_RowDeleted","ODS_DataPipeLineTaskQueueId"';
        
        -- update source column list
        AdditionalSourceCols := '
        , ST."StgId" as "ODS_StgId"
        , COALESCE(P."ParentId", -1) as "' ||ParentColName || '"
        , COALESCE(P."RootId", -1) AS "' || RootColName || '"
        , CURRENT_TIMESTAMP AS "ODS_RowCreatedDtTm"
        , false as "RowDeleted"
        , ' || CAST(TaskQueueId as VARCHAR) || ' as "DataPipeLineTaskQueueId"';

        JoinCondition := ' LEFT JOIN (SELECT * 
                                       FROM  public."udf_GetCleanTableParentId"(''' || MergeParams::TEXT || '''::JSONB)
                                      ) AS P ON P."StgId" = ST."StgId" ';

        WHERECondition := ' AND   NOT EXISTS (SELECT 1 FROM ' || CleanTableSchema || '."' || CleanTableName || '" AS C' ||
                          ' WHERE C."ODS_StgId" = ST."StgId")';

    END IF;

    -- Final SQL Code
    sql_code := ' INSERT INTO '
                || CleanTableSchema || '."' || CleanTableName || '" ' 
                || ' ( '
                || TargetCols || AdditionalTargetCols
                || ' ) '
                || ' SELECT '
                || SourceCols || AdditionalSourceCols
                || ' FROM ' || StageTableSchema || '."' || StageTableName || '" AS ST '
                || JoinCondition
                || ' WHERE "DataPipeLineTaskQueueId" = ' || CAST(PreStageToStageTaskId AS VARCHAR) || ' '
                || WHERECondition
                || ' RETURNING "ODS_StgId" AS "StgId", "' || PrimaryKeyName || '" AS "TableId" ;';
    RAISE NOTICE 'SQL Code to Insert: %', sql_code;

    IF sql_code IS NULL THEN
        RAISE EXCEPTION 'SQL Statement To Insert to 
                        Clean Table:%
                        From Stage Table: % is empty.
                        TargetCols: %
                        SourceCols: %
                        AdditionalTargetCols: %
                        AdditionalSourceCols: %
                        WHERECondition: %
                        JoinCondition: %
                        Check Params.'
                ,CleanTableName, StageTableName,TargetCols
                ,SourceCols ,AdditionalTargetCols ,AdditionalSourceCols
                ,WHERECondition,JoinCondition;
    END IF;

    -- This helps in debugging.
    IF (NoInsertPrintOnly IS NULL OR NoInsertPrintOnly = false) THEN
        RETURN QUERY EXECUTE sql_code;
    ELSE
        RETURN QUERY EXECUTE 'SELECT -100000, -100000';
    END IF;

END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_InsertCleanTable"(jsonb, boolean) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_InsertCleanTable"(jsonb, boolean) TO public;
/*
    --Testing code
    SELECT *
    FROM   public."udf_InsertCleanTable"('{"StageTable" : {
         "Schema": "stg",
         "TableName": "clients_clients",
         "ParentTableName": ""
         },
         "CleanTable" : {
            "Schema": "public",
            "TableName": "clients_clients",
            "ParentTableName": "",
            "PrimaryKeyName": "clientsId",
            "BusinessKeyColumn": "Rowkey",
            "RootTableName": ""
          },
          "PreStageToStageTaskId": 111,
          "TaskQueueId": 112}'::jsonb)

    SELECT *
    FROM   public."udf_InsertCleanTable"('{"StageTable" : {
         "Schema": "stg",
         "TableName": "clients_CurrentHealthPlanDesigns",
         "ParentTableName": "clients_clients"
         },
         "CleanTable" : {
            "Schema": "public",
            "TableName": "clients_CurrentHealthPlanDesigns",
            "ParentTableName": "clients_clients",
            "PrimaryKeyName": "CurrentHealthPlanDesignsId",
            "BusinessKeyColumn": "",
            "RootTableName": "clients_clients"
          },
          "PreStageToStageTaskId": 111,
          "TaskQueueId": 112}'::jsonb)
*/