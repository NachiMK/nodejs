DROP FUNCTION IF EXISTS public."udf_UpdateCleanTable"(varchar, varchar, varchar, varchar, varchar, bigint, bigint, varchar);
CREATE OR REPLACE FUNCTION public."udf_UpdateCleanTable"(
     StageTableSchema VARCHAR(256)
    ,StageTable VARCHAR(256)
    ,CleanTableSchema VARCHAR(256)
    ,CleanTable VARCHAR(256)
    ,PrimaryKeyName VARCHAR(256)
    ,TaskQueueId BIGINT 
    ,PreStageToStageTaskId BIGINT
    ,BusinessKeyColumn VARCHAR(256) DEFAULT '')
RETURNS TABLE (
     "StgId"    BIGINT
    ,"TableId"  BIGINT
) AS $$
DECLARE 
    sql_code text;
    Updatecols text;
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
    WHERE   CT."TableSchema" ~ CleanTableSchema
    AND     ST."TableSchema" ~ StageTableSchema
    AND     CT."TableName"   ~ CleanTable
    AND     ST."TableName"   ~ StageTable
    AND     CT."ColumnName" !~ PrimaryKeyName
    AND     CT."ColumnName" !~ BusinessKeyColumn
    AND     CT."ColumnName" !~ 'DataPipeLineTaskQueueId'
    AND     ST."ColumnName" !~ 'Stg';

    -- RAISE NOTICE 'Params:CleanTableSchema: %, StageTableSchema: %, CleanTable: %, StageTable: %, PrimaryKeyName: %, BusinessKeyColumn: %',
    -- CleanTableSchema,StageTableSchema,CleanTable,StageTable,PrimaryKeyName,BusinessKeyColumn;

    -- RAISE NOTICE 'Update Cols: %', Updatecols;

    sql_code := 'UPDATE ' || CleanTableSchema || '."'|| CleanTable ||'"
    SET     "EffectiveEndDate" = CASE WHEN CT."EffectiveStartDate"::DATE < stg."HistoryDate"::DATE
                                        THEN (stg."HistoryDate" - interval ''1 day'')::DATE
                                        ELSE CT."EffectiveStartDate"::DATE
                                    END
            ,"StgId" = stg."StgId"
            ,"Parent_Id" = -1
            ,"Root_Id" = -1
            ,"DataPipeLineTaskQueueId" = ' || CAST(TaskQueueId AS VARCHAR) || '
            ,' || Updatecols || '
    FROM    ' || CleanTableSchema || '."'|| CleanTable ||'" CT
    INNER
    JOIN    ' || StageTableSchema || '."'|| StageTable ||'" stg ON CT."'|| BusinessKeyColumn ||'" = stg."'|| BusinessKeyColumn ||'"
    WHERE   1 = 1
    AND     CT."EffectiveStartDate"::DATE <= stg."HistoryDate"::DATE
    AND     CT."EffectiveEndDate" = ''12-31-9999''
    AND     CT."RowDeleted" = false
    AND     stg."StgRowDeleted" = false
    AND     stg."DataPipeLineTaskQueueId" = ' || CAST(PreStageToStageTaskId as VARCHAR) || '
    RETURNING CT."StgId", CT."' || PrimaryKeyName || '" as "TableId";';
    RAISE NOTICE 'SQL Code to update %', sql_code;

    -- sql_code := 'SELECT CAST(1 as bigint), CAST(1 as bigint)';
    RETURN QUERY EXECUTE sql_code;

END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_UpdateCleanTable"(varchar, varchar, varchar, varchar, varchar, bigint, bigint, varchar) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_UpdateCleanTable"(varchar, varchar, varchar, varchar, varchar, bigint, bigint, varchar) TO public;
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