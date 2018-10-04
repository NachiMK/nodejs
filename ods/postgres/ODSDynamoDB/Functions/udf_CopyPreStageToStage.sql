-- udf_CopyPreStageToStage
DROP FUNCTION IF EXISTS public."udf_CopyPreStageToStage"(VARCHAR, VARCHAR, VARCHAR, VARCHAR, BIGINT);
CREATE OR REPLACE FUNCTION public."udf_CopyPreStageToStage"(
    StgTableSchema VARCHAR(256)
  , StgTableName VARCHAR(256)
  , PreStageSchema VARCHAR(256)
  , PreStageTable VARCHAR(256)
  , DataPipeLineTaskQueueId BIGINT
)
RETURNS BIGINT AS $$
    DECLARE dsql TEXT DEFAULT '';
    DECLARE InvalidTypes json DEFAULT NULL;
    DECLARE StageCount BIGINT DEFAULT 0;
BEGIN

    dsql = 'DELETE FROM ' || StgTableSchema || '."' || StgTableName 
            || '" WHERE "DataPipeLineTaskQueueId" = ' 
            || CAST(DataPipeLineTaskQueueId AS VARCHAR) || ';';
    RAISE NOTICE 'SQL to Delete Existing Rows %', dsql;
    EXECUTE dsql;

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
    )
    -- check if we dont have conversion functions, if so throw error
    SELECT array_to_json(array_agg(t))
    INTO   InvalidTypes
    FROM   (
        SELECT  R."DataType" as "PreStageType", S."DataType" as "StageType", COUNT(*) as "Cnt"
        FROM    CTEStageSchema S
        INNER
        JOIN    CTERawSchema  R ON S."ColumnName" = R."ColumnName"
        WHERE   (s."ColumnName" !~ 'StgId')
        AND NOT EXISTS (SELECT * FROM public."CastFunctionMapping" C 
                    WHERE UPPER(C."SourceType") = UPPER(R."DataType")
                    AND   UPPER(C."TargetType") = UPPER(S."DataType")
                    )
        AND     S."DataType" != R."DataType"
        GROUP BY R."DataType", S."DataType"
    ) t;
    
    IF InvalidTypes IS NOT NULL THEN
        RAISE EXCEPTION 'Some PreStage Types cannot be converted --> %', InvalidTypes::text
        USING HINT = 'Please check your PreStage data table types and Stage Table Data Types';
    END IF;

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
GRANT ALL on FUNCTION public."udf_CopyPreStageToStage"(varchar, varchar, varchar, varchar, bigint) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_CopyPreStageToStage"(varchar, varchar, varchar, varchar, bigint) TO public;
/*
    --Testing code
    SELECT *
    FROM   public."udf_CopyPreStageToStage('stg', 'clients', 'raw', 'clients_54_0_clients_181002_165354', 1);
*/