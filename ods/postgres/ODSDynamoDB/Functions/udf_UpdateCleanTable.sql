DROP FUNCTION IF EXISTS public."udf_UpdateCleanTable"(varchar, varchar, varchar, varchar, varchar, bigint, bigint, varchar, boolean);
CREATE OR REPLACE FUNCTION public."udf_UpdateCleanTable"(
     StageTableSchema VARCHAR(256)
    ,StageTable VARCHAR(256)
    ,CleanTableSchema VARCHAR(256)
    ,CleanTable VARCHAR(256)
    ,PrimaryKeyName VARCHAR(256)
    ,TaskQueueId BIGINT 
    ,PreStageToStageTaskId BIGINT
    ,BusinessKeyColumn VARCHAR(256) DEFAULT ''
    ,NoUpdatePrintOnly BOOLEAN DEFAULT FALSE)
RETURNS TABLE (
     "StgId"    BIGINT
    ,"TableId"  BIGINT
) AS $$
DECLARE 
    sql_code text;
    Updatecols text;
    UpdatedEndDate json;
    UpdatedAllCols json;
BEGIN
-- Existing: 1/1/2018 to 12/31/9999
-- INcoming: 1/2/2018 to 12/31/9999 
    -- => change existing to 1/1/2018 to 1/1/2018
    -- => Set End date to New Start Date - 1
-- Incoming: 1/5/2018 to 12/31/9999
    -- => change existing to 1/1/2018 to 1/4/2018
    -- => Set End date to New Start Date - 1
-- Incoming: 1/1/2018 to 12/31/9999
    -- => No change to existing
    -- => Set End date to New Start Date
-- Never change start date.
-- End date is always <= TODAY or 12/31/9999

    SELECT  --CT."QuotedColumnName", ST."QuotedColumnName" ,CT."QuotedColumnName" || ' = ST.' || ST."QuotedColumnName"
            STRING_AGG(CT."QuotedColumnName" || ' = stg.' || ST."QuotedColumnName", ',')
    INTO    Updatecols
    FROM    public."vwColumnDefinition" as CT
    INNER
    JOIN    public."vwColumnDefinition" as ST ON CT."ColumnName" = ST."ColumnName"
    WHERE   CT."TableSchema" = CleanTableSchema
    AND     ST."TableSchema" = StageTableSchema
    AND     CT."TableName"   = CleanTable
    AND     ST."TableName"   = StageTable
    AND     CT."ColumnName" !~ PrimaryKeyName
    AND     CT."ColumnName" !~ BusinessKeyColumn
    AND     CT."ColumnName" !~ 'ODS_DataPipeLineTaskQueueId'
    AND     ST."ColumnName" !~ 'Stg';

    RAISE NOTICE 'Params:CleanTableSchema: %, StageTableSchema: %, CleanTable: %, StageTable: %, PrimaryKeyName: %, BusinessKeyColumn: %',
    CleanTableSchema,StageTableSchema,CleanTable,StageTable,PrimaryKeyName,BusinessKeyColumn;

    RAISE NOTICE 'Update Cols: %', Updatecols;

    sql_code := 'WITH CTEEndRecord AS (
    UPDATE ' || CleanTableSchema || '."'|| CleanTable ||'" AS CT
    SET     "ODS_EffectiveEndDate" = (stg."HistoryCreated" - interval ''1 day'')::DATE
    FROM    ' || StageTableSchema || '."'|| StageTable ||'" stg
    WHERE   1 = 1
    AND     CT."'|| BusinessKeyColumn ||'" = stg."'|| BusinessKeyColumn ||'"
    AND     CT."ODS_EffectiveStartDate"::DATE < stg."HistoryCreated"::DATE
    AND     CT."ODS_EffectiveEndDate" = ''12-31-9999''
    AND     CT."ODS_RowDeleted" = false
    AND     stg."StgRowDeleted" = false
    AND     stg."DataPipeLineTaskQueueId" = ' || CAST(PreStageToStageTaskId as VARCHAR) || '
    RETURNING CT."ODS_StgId" AS "StgId", CT."' || PrimaryKeyName || '" as "TableId"
    )
    SELECT array_to_json(array_agg(row_to_json(t)))
    FROM (SELECT * FROM CTEEndRecord) AS t;';

    IF NoUpdatePrintOnly IS NULL OR NoUpdatePrintOnly = FALSE THEN
        EXECUTE sql_code INTO UpdatedEndDate;
    ELSE
        RAISE NOTICE 'SQL Code to update Dates %', sql_code;    
    END IF;

    sql_code := 'WITH CTEUpdateAll AS (
    UPDATE ' || CleanTableSchema || '."'|| CleanTable ||'" AS CT
    SET      "ODS_StgId" = stg."StgId"
            ,"ODS_DataPipeLineTaskQueueId" = ' || CAST(TaskQueueId AS VARCHAR) || '
            ,' || Updatecols || '
    FROM    ' || StageTableSchema || '."'|| StageTable ||'" stg
    WHERE   1 = 1
    AND     CT."'|| BusinessKeyColumn ||'" = stg."'|| BusinessKeyColumn ||'"
    AND     CT."ODS_EffectiveStartDate"::DATE = stg."HistoryCreated"::DATE
    AND     CT."ODS_EffectiveEndDate" = ''12-31-9999''
    AND     CT."ODS_RowDeleted" = false
    AND     stg."StgRowDeleted" = false
    AND     stg."DataPipeLineTaskQueueId" = ' || CAST(PreStageToStageTaskId as VARCHAR) || '
    RETURNING CT."ODS_StgId" AS "StgId", CT."' || PrimaryKeyName || '" as "TableId"
    )
    SELECT array_to_json(array_agg(row_to_json(t)))
    FROM (SELECT * FROM CTEUpdateAll) AS t;';

    IF NoUpdatePrintOnly IS NULL OR NoUpdatePrintOnly = FALSE THEN
        EXECUTE sql_code INTO UpdatedAllCols;
    ELSE
        RAISE NOTICE 'SQL Code to update %', sql_code;
    END IF;

    sql_code :='
    SELECT   CAST(CAST(T->''StgId'' AS VARCHAR(20)) AS BIGINT) AS "StgId"
            ,CAST(CAST(T->''TableId'' AS VARCHAR(20)) AS BIGINT) AS "TableId"
    FROM    json_array_elements($1) as T
    UNION
    SELECT   CAST(CAST(T->''StgId'' AS VARCHAR(20)) AS BIGINT) AS "StgId"
            ,CAST(CAST(T->''TableId'' AS VARCHAR(20)) AS BIGINT) AS "TableId"
    FROM    json_array_elements($2) as T';

    IF NoUpdatePrintOnly IS NULL OR NoUpdatePrintOnly = FALSE THEN
        RETURN QUERY EXECUTE sql_code USING UpdatedEndDate, UpdatedAllCols;
    ELSE
        RAISE NOTICE 'SQL Code to return updated rows %', sql_code;
        RETURN QUERY EXECUTE 'SELECT -10000 AS "StgId", -10000 AS "TableId"';
    END IF;

END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_UpdateCleanTable"(varchar, varchar, varchar, varchar, varchar, bigint, bigint, varchar, boolean) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_UpdateCleanTable"(varchar, varchar, varchar, varchar, varchar, bigint, bigint, varchar, boolean) TO public;
/*
    -- Testing code
    SELECT  *
    FROM "udf_UpdateCleanTable"(
         'Stg'
        ,'clients_CurrentHealthPlanDesigns'
        ,'public'
        ,'clients_CurrentHealthPlanDesigns'
        ,'CurrentHealthPlanDesignsId'
        ,117
        ,111
        ,'')
    )
*/