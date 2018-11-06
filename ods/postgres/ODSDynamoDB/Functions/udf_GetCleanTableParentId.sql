-- udf_GetCleanTableParentId
DROP FUNCTION IF EXISTS public."udf_GetCleanTableParentId"(jsonb);
CREATE OR REPLACE FUNCTION public."udf_GetCleanTableParentId"(MergeParams jsonb)
RETURNS TABLE (
     "StgId" bigint
    ,"StgParentId" bigint
    ,"ParentId" bigint
    ,"RootId" bigint)
LANGUAGE plpgsql
AS $$
DECLARE 
    sql_code TEXT;
    sql_get_rows TEXT;
    FieldList VARCHAR(500);
    ParentPKcol VARCHAR(256);
    StageTableSchema VARCHAR(256);
    StageTableName VARCHAR(256);
    StageTableParentName VARCHAR(256);
    CleanTableSchema VARCHAR(256);
    CleanTableName VARCHAR(256);
    CleanTableParentName VARCHAR(256);
    RootTableName VARCHAR(256);
    PreStageToStageTaskId BIGINT;
    StgRowCount BIGINT DEFAULT -1;
    ParentCnt BIGINT DEFAULT -1;
BEGIN

    SELECT "StgTableSchema"
          ,"StgTableName"
          ,"ParentStgTableName"
          ,"CleanTableSchema"
          ,"CleanTableName"
          ,"CleanParentTableName"
          ,"PreStageToStageTaskId"
          ,"RootTableName"
    INTO   StageTableSchema
          ,StageTableName
          ,StageTableParentName
          ,CleanTableSchema
          ,CleanTableName
          ,CleanTableParentName
          ,PreStageToStageTaskId
          ,RootTableName
    FROM  public."udf_ParseMergeParams"(MergeParams);

    -- Get Stage Count
    sql_code := 'SELECT   COUNT(*) FROM '|| StageTableSchema || '."' || StageTableName || '" sc1
                 WHERE    sc1."DataPipeLineTaskQueueId" = '|| CAST(PreStageToStageTaskId AS VARCHAR);
    EXECUTE sql_code INTO StgRowCount;
    RAISE NOTICE 'Count: %, by SQL: %', StgRowCount, sql_code;
    RAISE NOTICE 'CleanTableParentName: %, StageTableParentName: %', CleanTableParentName, StageTableParentName;

    -- Check if we can find Parent Ids for all Child rows.
    -- if not throw an error
    sql_code := '';
    IF (LENGTH(CleanTableParentName) > 0 )
        AND (LENGTH(StageTableParentName) > 0) 
        AND (StgRowCount > 0) THEN

        sql_get_rows := '
        SELECT   <FieldList>
        FROM    '|| StageTableSchema || '."' || StageTableName || '" sc1
        INNER 
        JOIN    '|| StageTableSchema || '."' || StageTableParentName || '" sp1 ON  sc1."ODS_Parent_Uri" = sp1."ODS_Uri"
                                                            AND  sc1."ODS_Batch_Id" = sp1."ODS_Batch_Id"
                                                            AND  sc1."DataPipeLineTaskQueueId" = sp1."DataPipeLineTaskQueueId"
        INNER
        JOIN    '|| CleanTableSchema || '."' || CleanTableParentName || '" cp1 ON cp1."DataPipeLineTaskQueueId" = sp1."DataPipeLineTaskQueueId"
                                                            AND cp1."StgId" = sp1."StgId"
        WHERE   sc1."DataPipeLineTaskQueueId" = '|| CAST(PreStageToStageTaskId AS VARCHAR) || '
        AND     cp1."RowDeleted" = false;';

        -- query for # of Parent records
        sql_code := REPLACE(sql_get_rows, '<FieldList>', 'COUNT(*)');
        EXECUTE sql_code INTO ParentCnt;

        IF StgRowCount != ParentCnt THEN
            RAISE EXCEPTION 'Parent Key NOT FOUND. Parent missing in Table %, Stage Count: %, Parent Count:% '
                , CleanTableParentName, StgRowCount, ParentCnt;
        END IF;

        -- get Primary key of Parent
        sql_code := '
            SELECT a.attname as ParentPKcol
            FROM   pg_index i
            JOIN   pg_attribute a ON a.attrelid = i.indrelid
                                AND a.attnum = ANY(i.indkey)
            WHERE  i.indrelid = (
                                    SELECT  pc.oid
                                    FROM    pg_class pc
                                    INNER 
                                    JOIN    pg_namespace pr on pr.oid = pc.relnamespace
                                    WHERE   relname     ~* '''|| CleanTableParentName || '''
                                    AND     pr.nspname  ~* '''|| CleanTableSchema || '''
                                )
            AND    i.indisprimary;';
        RAISE NOTICE 'SQL Query to get PK Column: %', sql_code;
        EXECUTE sql_code INTO ParentPKcol;

        -- get Root key of Parent
        IF RootTableName != '' AND RootTableName = ParentTableName THEN
            RootColName := ParentPKcol;
        ELSE 
            sql_code := '
                SELECT  column_name 
                FROM    INFORMATION_SCHEMA.COLUMNS C
                WHERE   C.table_schema ~* ''' || CleanTableSchema || '''
                AND     C.table_name ~* ''' || CleanTableName || '''
                AND     C.column_name ~ ''Root_.*Id''
                AND     EXISTS 
                        (
                            SELECT  1
                            FROM    INFORMATION_SCHEMA.COLUMNS AS R
                            WHERE   R.table_schema = c.table_schema
                            AND     R.table_name ~* ''' || RootTableName || '''
                            AND     R.column_name ~* REPLACE(C.column_name, ''Root_'', '''')
                        );';
            RAISE NOTICE 'SQL Query to get Root Column: %', sql_code;
            EXECUTE sql_code INTO RootColName;

            IF RootColName ~* 'Root_Id' THEN
                RootColName := ParentPKcol;
            END IF;

            IF RootColName IS NULL OR LENGTH(RootColName) = 0 THEN
                RAISE EXCEPTION 'RootColName is null or empty. Please Check, Parent: %', CleanParentTableName;
            END IF;
        END IF;

        -- If row counts match then get rows
        FieldList := ' sc1."StgId", sp1."StgId" as "StgParentId"
                        ,cp1."'|| CAST(ParentPKcol AS VARCHAR) || '" as "ParentId"
                        ,cp1."'|| CAST(RootColName AS VARCHAR) || '" as "RootId" ';
        sql_code := REPLACE(sql_get_rows, '<FieldList>', FieldList);
    ELSE
        sql_code := 'SELECT   sc1."StgId", CAST(-1 as BIGINT) as "StgParentId"
                     , CAST(-1 as BIGINT) as "ParentId" , CAST(-1 as BIGINT) as "RootId" 
                     FROM '|| StageTableSchema || '."' || StageTableName || '" sc1
                     WHERE    sc1."DataPipeLineTaskQueueId" = '|| CAST(PreStageToStageTaskId AS VARCHAR);
    END IF;

    RAISE NOTICE 'SQL Query to get Parent: %', sql_code;
    RETURN QUERY EXECUTE sql_code;

END;
$$;
GRANT ALL on FUNCTION public."udf_GetCleanTableParentId"(jsonb) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_GetCleanTableParentId"(jsonb) TO public;
/*
    --Testing code
    SELECT *
    FROM   public."udf_GetCleanTableParentId"('{"StageTable" : {
         "Schema": "stg",
         "TableName": "clients_CurrentHealthPlanDesigns",
         "ParentTableName": "clients_clients"
         },
         "CleanTable" : {
            "Schema": "public",
            "TableName": "clients_CurrentHealthPlanDesigns",
            "ParentTableName": "clients_clients",
            "PrimaryKeyName": "",
            "BusinessKeyColumn": "",
            "RootTableName": "clients_clients"
          },
          "PreStageToStageTaskId": 111,
          "TaskQueueId": 2}'::jsonb)
*/
