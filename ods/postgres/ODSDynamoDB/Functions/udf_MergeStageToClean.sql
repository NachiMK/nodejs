-- udf_MergeStageToClean
DROP FUNCTION IF EXISTS public."udf_MergeStageToClean"(jsonb);
CREATE OR REPLACE FUNCTION public."udf_MergeStageToClean"(
    MergeParams jsonb
)
RETURNS BIGINT AS $$
    DECLARE dsql TEXT DEFAULT '';
    DECLARE blnIsValid BOOLEAN DEFAULT false;
    DECLARE StageCount BIGINT DEFAULT 0;

    DECLARE CleanTblCount BIGINT DEFAULT 0;
    
    DECLARE StgTableSchema VARCHAR(256) DEFAULT '';
    DECLARE StgTableName VARCHAR(256) DEFAULT '';
    DECLARE ParentStgTableName VARCHAR(256) DEFAULT '';

    DECLARE CleanTableSchema VARCHAR(256) DEFAULT '';
    DECLARE CleanTableName VARCHAR(256) DEFAULT '';
    DECLARE ParentTableName VARCHAR(256) DEFAULT '';
    DECLARE PrimaryKeyName VARCHAR(256) DEFAULT '';

    DECLARE PreStageToStageTaskId BIGINT DEFAULT -1;
    DECLARE TaskQueueId BIGINT DEFAULT -1;
BEGIN
    /*
        MergeParams := 
        {
            StageTable : {
                Schema: 'stg',
                TableName: 'clients_clients',
                ParentTableName: '',
            },
            CleanTable : {
                Schema: 'public',
                TableName: 'clients_clients',
                ParentTableName: '',
                PrimaryKeyName: ''
            },
            PreStageToStageTaskId: 1,
            TaskQueueId: 2
        }
        How it works?
        - No validation is done, assumption is, it is taken care before this step
        - Parameters are cleaned & defaults are assigned for easy processing
        - Find Stage Row Count
        - If Stage has rows proceed or else return 0
        - Index Tables if needed so that queries run faster
            - Index Stage Table
            - Index Clean Tables
        - Find Parent Id if ParentTable is provided
        - Get all rows, Parent Id if applicable, Effective Dates
        - Merge
            - Insert (if inserting, update prior record as expired), update on conflict
            - Check if Stage has a columns called "<PrimaryKeyName>", if so conflict should be based
                on PrimaryKeyName, ParentId, EffectiveStartDate, EffectiveEndDate
    */
    SELECT public."udf_ValidateStageToClean"(MergeParams)
    INTO   blnIsValid;

    /*
        -- Parameters
    */
    WITH CTEParams
    AS
    (
    SELECT
         CAST(param->'StageTable'->>'Schema' AS VARCHAR) as "StageTableSchema"
        ,CAST(param->'StageTable'->>'TableName' AS VARCHAR) as "StageTableName"
        ,CAST(param->'StageTable'->>'ParentTableName' AS VARCHAR) as "StageParentTableName"
        ,CAST(param->'CleanTable'->>'Schema' AS VARCHAR) as "CleanTableSchema"
        ,CAST(param->'CleanTable'->>'TableName' AS VARCHAR) as "CleanTableName"
        ,CAST(param->'CleanTable'->>'ParentTableName' AS VARCHAR) as "CleanParentTableName"
        ,CAST(param->'PreStageToStageTaskId' AS INT) as "PreStageToStageTaskId"
        ,CAST(param->'TaskQueueId' AS INT) as "TaskQueueId"
    FROM (SELECT MergeParams as param) as p
    )
    SELECT  "StageTableSchema"
            ,"StageTableName"
            ,"StageParentTableName"
            ,"CleanTableSchema"
            ,"CleanTableName"
            ,"CleanParentTableName"
            ,"PreStageToStageTaskId"
            ,"TaskQueueId"
    INTO     StgTableSchema
            ,StgTableName
            ,ParentStgTableName
            ,CleanTableSchema
            ,CleanTableName
            ,CleanParentTableName
            ,PreStageToStageTaskId
            ,TaskQueueId
    FROM    CTEParams;

    /*
        -- Index for faster access
    */
    SELECT public."udf_IndexStageTable"(StgTableSchema, StgTableName);
    SELECT public."udf_IndexStageTable"(StgTableSchema, ParentStgTableName);
    SELECT public."udf_IndexCleanTable"(CleanTableSchema, CleanTableName);
    SELECT public."udf_IndexCleanTable"(CleanTableSchema, ParentTableName);

    /*
        StgId   ParentId
        ----------------
    */
    SELECT public."udf_GetCleanTableParentId"(StgTableName, ParentStgTableName, ParentTableName)
    
    /*
        Comma Separated List of columns
    */
    SELECT public."udf_GetMergeColumns"(StgTableName, CleanTableName)

    -- statement to add DATA
    WITH CTERawSchema
    AS
    (
        SELECT   PS."Position"
                ,PS."ColumnName"
                ,PS."IsNullable"
                ,PS."DataType"
                ,PS."DataLength"
                ,PS."precision"
                ,PS."scale"
                ,PS."DataTypeWithLen"
                ,PS.udt_name
        FROM    public."vwColumnDefinition" as PS
        WHERE   PS."TableSchema" = PreStageSchema
        AND     PS."TableName" = PreStageTable
    ),
    CTEStageSchema
    AS
    (
        SELECT   PS."Position"
                ,PS."ColumnName"
                ,PS."IsNullable"
                ,PS."DataType"
                ,PS."DataLength"
                ,PS."precision"
                ,PS."scale"
                ,PS."DataTypeWithLen"
                ,PS.udt_name
        FROM    public."vwColumnDefinition" as PS
        WHERE   PS."TableSchema" = StgTableSchema
        AND     PS."TableName" = StgTableName
    ),
    CTEColList
    AS
    (
        SELECT  
            CASE WHEN R."ColumnName" IS NOT NULL AND C."CastFunction" IS NOT NULL
                THEN  'public."' || C."CastFunction" || '"(R."' || R."ColumnName" || '") as "' || S."ColumnName" || '"'
            WHEN R."ColumnName" IS NOT NULL AND R."DataType" = S."DataType" 
                THEN 'R."' || R."ColumnName" || '" as "' || S."ColumnName" || '"'
            ELSE
                CASE WHEN (s."ColumnName" ~ 'StgRowCreatedDtTm') 
                        THEN 'CURRENT_TIMESTAMP AS "' || S."ColumnName" || '"'
                    WHEN (s."ColumnName" ~ 'StgRowDeleted')
                        THEN 'false as "' || S."ColumnName" || '"'
                    WHEN (s."ColumnName" ~ 'DataPipeLineTaskQueueId')
                        THEN  CAST(DataPipeLineTaskQueueId as VARCHAR) || ' as "' || S."ColumnName" || '"'
                    ELSE 'null as "' || S."ColumnName" || '"'
                END
            END as "SelectColumns"
            ,'"' || S."ColumnName" || '"' as "InsertColumns"
        FROM    CTEStageSchema S
        LEFT
        JOIN    CTERawSchema  R ON S."ColumnName" = R."ColumnName"
        LEFT
        JOIN    public."CastFunctionMapping" C  ON  UPPER(C."SourceType") = UPPER(R."DataType")
                                                AND UPPER(C."TargetType") = UPPER(S."DataType")
                                                AND S."DataType" != R."DataType"
        WHERE   (s."ColumnName" !~ 'StgId')
        ORDER BY  S."Position"
    )
    SELECT  
            'INSERT INTO '|| StgTableSchema ||'."'|| StgTableName ||'" ' 
            || E'\n' || '(' || string_agg("InsertColumns"::text, E'\n' || ',') || ')'
            || E'\n' || ' SELECT ' || E'\n' || string_agg("SelectColumns"::text, E'\n' || ',')
            || E'\n' || ' FROM '|| PreStageSchema ||'."'|| PreStageTable ||'" AS R;'
    INTO    dsql    
    FROM    CTEColList
    ;
    RAISE NOTICE 'Insert Statement PreStage %s to Stage:%, %', PreStageTable, StgTableSchema, dsql;
    EXECUTE dsql;

    dsql := 'SELECT COUNT(*) FROM ' || StgTableSchema || '.' || '"' || StgTableName 
            || '" WHERE "DataPipeLineTaskQueueId" = '
            || CAST(DataPipeLineTaskQueueId AS VARCHAR) || ';';
    RAISE NOTICE 'Count after Stage table update: %', dsql;
    EXECUTE dsql INTO StageCount;

    RETURN StageCount;
END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_MergeStageToClean"(jsonb) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_MergeStageToClean"(jsonb) TO public;
/*
    --Testing code
    SELECT *
    FROM   public."udf_MergeStageToClean"('{"StageTable" : {
         "Schema": "stg",
         "TableName": "clients_clients",
         "ParentTableName": ""
         },
         "CleanTable" : {
            "Schema": "public",
            "TableName": "clients_clients",
            "ParentTableName": "",
            "PrimaryKeyName": ""
          },
          "PreStageToStageTaskId": 1,
          "TaskQueueId": 2}'::jsonb)
*/