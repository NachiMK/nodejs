DROP FUNCTION IF EXISTS public."udf_IndexStageTable"(VARCHAR, VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION public."udf_IndexStageTable"(userTableSchema VARCHAR(256)
                                                        , userTableName VARCHAR(256)
                                                        , RowKeyColName VARCHAR(100) DEFAULT '')
RETURNS VOID AS $$
    DECLARE dsql TEXT DEFAULT '';
    DECLARE blnIsValid BOOLEAN DEFAULT false;
    DECLARE StgIndexPrefix VARCHAR(256) DEFAULT 'StgIdx_';
    DECLARE StgIndexName VARCHAR(256) DEFAULT '';
    DECLARE DeleteIdxCols VARCHAR(256) DEFAULT '"DataPipeLineTaskQueueId", "StgRowDeleted"';
    DECLARE UriIdxCols VARCHAR(256) DEFAULT '"DataPipeLineTaskQueueId","ODS_Parent_Uri","ODS_Uri"';
    DECLARE DEFAULT_ROWKEY_COL VARCHAR(100) DEFAULT '"Rowkey"';
    DECLARE RowKeyIdxCols VARCHAR(256) DEFAULT '';
    DECLARE blnIdxCreated BOOLEAN;

BEGIN    
    
    IF RowKeyColName IS NULL OR LENGTH(RowKeyColName) = 0 THEN
        RowKeyIdxCols = DEFAULT_ROWKEY_COL;
    ELSE
        RowKeyIdxCols = RowKeyColName;
    END IF;

    IF LENGTH(userTableSchema) > 0 AND LENGTH(userTableName) > 0 AND 
        EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
                WHERE table_name = userTableName and table_schema = userTableSchema) THEN
        blnIsValid := true;
    END IF;

    -- proceed only if valid
    IF blnIsValid = true THEN
        -- Form index name
        StgIndexName := StgIndexPrefix || userTableName || '_DeleteFilter';
       -- create first index
       PERFORM public."udf_CreateIndex"(userTableSchema, userTableName, StgIndexName, DeleteIdxCols);

        -- SECOND INDEX
        StgIndexName := StgIndexPrefix || userTableName || '_UriCols';
       -- create Uri col index
       PERFORM public."udf_CreateIndex"(userTableSchema, userTableName, StgIndexName, UriIdxCols);

        -- Create Rowkey index only if the table has such column name
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE table_name = userTableName AND LOWER(column_name) = LOWER(REPLACE(RowKeyColName, '"', ''))
                  AND   table_schema = userTableSchema) THEN
            -- Third Index
            StgIndexName := StgIndexPrefix || userTableName || '_Rowkey';
            -- create Rowkey col index
            PERFORM public."udf_CreateIndex"(userTableSchema, userTableName, StgIndexName, RowKeyIdxCols);
        END IF;
    END IF;

    RETURN;
END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_IndexStageTable"(varchar, varchar, varchar) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_IndexStageTable"(varchar, varchar, varchar) TO public;

/*
    -- testing code
        SELECT public."udf_IndexStageTable"('public', '_nm_testIndex', '"Rowkey1"');
        SELECT public."udf_IndexStageTable"('public', '_nm_testIndex', '"Rowkey"');

        DROP INDEX stgidx__nm_testIndex_deletefilter;
        DROP INDEX stgidx__nm_testIndex_UriCols;
        DROP INDEX stgidx__nm_testIndex_rowkey;

        DROP TABLE public."_nm_testIndex";

        CREATE TABLE public."_nm_testIndex"(
        "DataPipeLineTaskQueueId" int
        ,"StgRowDeleted" boolean
        ,"ODS_Parent_Uri" varchar
        ,"ODS_Uri" varchar
        ,"Rowkey" varchar);

        SELECT  *
        FROM    pg_indexes as pgi
        WHERE   pgi.schemaname = 'public'
        and     pgi.tablename  = '_nm_testIndex'
        ;
*/