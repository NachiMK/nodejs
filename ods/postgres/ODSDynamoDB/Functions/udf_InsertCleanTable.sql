-- udf_InsertCleanTable
DROP FUNCTION IF EXISTS public."udf_InsertCleanTable"(jsonb);
CREATE OR REPLACE FUNCTION public."udf_InsertCleanTable"(MergeParams jsonb)
RETURNS TABLE (
     "StgId"    BIGINT
    ,"TableId"  BIGINT
) AS $$
DECLARE 
    sql_code text;
    InsertCols text;
    StgTableSchema VARCHAR(256);
    StgTableName VARCHAR(256);
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
BEGIN
    SELECT   "StageTableSchema"
            ,"StageTableName"
            ,"StageParentTableName"
            ,"CleanTableSchema"
            ,"CleanTableName"
            ,"CleanParentTableName"
            ,"PrimaryKeyName"
            ,"BusinessKeyColumn"
            ,"RootTableName"
            ,CAST("PreStageToStageTaskId" as INT)
            ,CAST("TaskQueueId" AS INT)
            ,CASE WHEN LENGTH("BusinessKeyColumn") > 0 THEN TRUE ELSE FALSE END AS IsRootTable
    INTO     StgTableSchema
            ,StgTableName
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
            ,STRING_AGG(ST."QuotedColumnName", ',') as sourceCols
    INTO    TargetCols, SourceCols
    FROM    public."vwColumnDefinition" as CT
    INNER
    JOIN    public."vwColumnDefinition" as ST ON CT."ColumnName" = ST."ColumnName"
    WHERE   CT."TableSchema" ~ CleanTableSchema
    AND     ST."TableSchema" ~ StageTableSchema
    AND     CT."TableName"   ~ CleanTable
    AND     ST."TableName"   ~ StageTable
    AND     CT."ColumnName" !~ PrimaryKeyName
    AND     CT."ColumnName" !~ BusinessKeyColumn
    AND     CT."ColumnName" !~ 'DataPipeLineTaskQueueId';

    IF IsRootTable THEN
        -- If Root no Parent or Root is required.
        AdditionalTargetCols := ',"Parent_Id","Root_Id","EffectiveStartDate"' ||
                                ',"EffectiveEndDate","RowCreatedDtTm","RowDeleted"'||
                                ',"DataPipeLineTaskQueueId", "' || BusinessKeyColumn || '"' ;
        -- source columns
        AdditionalSourceCols := '
        , -1 as "Parent_Id"
        , -1 AS "Root_Id"
        , stg."HistorDate"::DATE as "EffectiveStartDate"
        , ''12/31/9999'' as "EffectiveEndDate"
        , CURRENT_TIMESTAMP AS "RowCreatedDtTm"
        , false as "RowDeleted"
        , ' || CAST(TaskQueueId as VARCHAR) || ' as "DataPipeLineTaskQueueId"
        , ST."' || BusinessKeyColumn || '" AS BusinessKeyColumn as ;';

        WHERECondition := ' AND   NOT EXISTS (SELECT 1 FROM CleanTableSchema.CleanTableName AS C' ||
                          ' WHERE C.BusinessKeyColumn = ST.BusinessKeyColumn ' ||
                          ' AND   C.EffectiveStartDate = ST.HistoryDate::date ' ||
                          ' AND   C.EffectiveEndDate = ''12-31-9999'')';
    ELSE
        -- Find my Parent Column
        SELECT  column_name
        INTO    ParentColName
        FROM    INFORMATION_SCHEMA.COLUMNS
        WHERE   table_schema ~* CleanTableSchema
        AND     table_name   ~* CleanTableName
        AND     column_name ~* 'Parent_.*Id';

        -- find my Root Column from my parent.
        SELECT  column_name
        INTO    RootColName
        FROM    INFORMATION_SCHEMA.COLUMNS
        WHERE   table_schema ~* CleanTableSchema
        AND     table_name   ~* CleanTableName
        AND     column_name ~* 'Root_.*Id';

        -- update the Target col list for inserting
        AdditionalTargetCols := '"' ||ParentColName || '","' || RootColName || 
        '","RowCreatedDtTm","RowDeleted","DataPipeLineTaskQueueId"';
        
        -- update source column list
        AdditionalSourceCols := '
        , "ParentId" as "' ||ParentColName || '"
        , "RootId" AS "' || RootColName || '"
        , CURRENT_TIMESTAMP AS "RowCreatedDtTm"
        , false as "RowDeleted"
        , ' || CAST(TaskQueueId as VARCHAR) || ' as "DataPipeLineTaskQueueId"';
    END IF;

    INSERT INTO 
        CleanTableSchema.CleanTable 
        (
            TargetCols + AdditionalTargetCols
        )
    SELECT 
        (
            SourceCols + AdditionalSourceCols
        )
    FROM StageTableSchema.StageTableName AS ST
    WHERE DataPipeLineTaskQueueId = PreStageToStageTaskId
    ;

    RAISE NOTICE 'SQL Code to Insert: %', sql_code;
    RETURN QUERY EXECUTE sql_code;
END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_InsertCleanTable"(jsonb) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_InsertCleanTable"(jsonb) TO public;
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
            "PrimaryKeyName": "",
            "BusinessKeyColumn": "",
            "RootTableName": ""
          },
          "PreStageToStageTaskId": 1,
          "TaskQueueId": 2}'::jsonb)
*/