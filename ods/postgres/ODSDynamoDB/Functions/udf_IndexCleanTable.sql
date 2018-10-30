--udf_IndexCleanTable
DROP FUNCTION IF EXISTS public."udf_IndexCleanTable"(VARCHAR, VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION public."udf_IndexCleanTable"(userTableSchema VARCHAR(256)
                                                        , userTableName VARCHAR(256)
                                                        , PrimarykeyColName VARCHAR(100) DEFAULT '')
RETURNS VOID AS $$
    DECLARE dsql TEXT DEFAULT '';
    DECLARE blnIsValid BOOLEAN DEFAULT false;
    DECLARE CleanIdxPrefix VARCHAR(256) DEFAULT 'IDX_';
    DECLARE CleanIdxName VARCHAR(256) DEFAULT '';
    DECLARE DeleteIdxCols VARCHAR(256) DEFAULT '"DataPipeLineTaskQueueId","RowDeleted"';
    DECLARE UriIdxCols VARCHAR(256) DEFAULT '"DataPipeLineTaskQueueId","ODS_Parent_Uri","ODS_Uri"';
    DECLARE DimType2Cols VARCHAR(256) DEFAULT '<Primarykey>"ParentId","EffectiveStartDate","EffectiveEndDate"';
    DECLARE DEFAULT_ROWKEY_COL VARCHAR(100) DEFAULT '"Rowkey"';
    DECLARE PKColName VARCHAR(256) DEFAULT '';
    DECLARE blnIdxCreated BOOLEAN;
    DECLARE colCnt BIGINT DEFAULT 0;

BEGIN    
    
    IF (PrimarykeyColName IS NOT NULL) AND (LENGTH(PrimarykeyColName) > 0) THEN
        PKColName = PrimarykeyColName;
    END IF;

    IF LENGTH(userTableSchema) > 0 AND LENGTH(userTableName) > 0 AND 
        EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
                WHERE table_name = userTableName and table_schema = userTableSchema) THEN
        blnIsValid := true;
    END IF;

    -- proceed only if valid
    IF blnIsValid THEN
        -- Form index name
        CleanIdxName := CleanIdxPrefix || userTableName || '_DeleteFilter';
        -- create first index
        PERFORM public."udf_CreateIndex"(userTableSchema, userTableName, CleanIdxName, DeleteIdxCols);

        -- SECOND INDEX
        CleanIdxName := CleanIdxPrefix || userTableName || '_UriCols';
        -- create Uri col index
        PERFORM public."udf_CreateIndex"(userTableSchema, userTableName, CleanIdxName, UriIdxCols);

        -- if primary key is not provided then create one with just type2 cols
        blnIsValid :=  false;
        IF (LENGTH(PKColName) = 0) OR (PKColName IS NULL) THEN
            DimType2Cols := REPLACE(DimType2Cols, '<Primarykey>', '');
            blnIsValid :=  true;
        ELSE
            -- if not include the primary key col
            IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                       WHERE table_name = userTableName 
                       AND   LOWER(column_name) = LOWER(REPLACE(PKColName, '"', ''))
                       AND   table_schema = userTableSchema) THEN
                DimType2Cols := REPLACE(DimType2Cols, '<Primarykey>', PKColName || ',');
                blnIsValid :=  true;
            END IF;
        END IF;

        -- get type 2 col count
        SELECT  COUNT(*) 
        INTO    colCnt
        FROM    INFORMATION_SCHEMA.COLUMNS
        WHERE   table_name = userTableName 
        AND     LOWER(column_name) IN (
                        LOWER('EffectiveStartDate'),
                        LOWER('EffectiveEndDate'),
                        LOWER('ParentId')
                ) 
        AND     table_schema = userTableSchema;

        -- does table have effective start and end date
        IF (colCnt >= 3) AND blnIsValid THEN
            -- Third Index
            CleanIdxName := CleanIdxPrefix || userTableName || '_Type2Idx';
            -- create Rowkey col index
            PERFORM public."udf_CreateIndex"(userTableSchema, userTableName, CleanIdxName, DimType2Cols);
        END IF;

    END IF;

    RETURN;
END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_IndexCleanTable"(varchar, varchar, varchar) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_IndexCleanTable"(varchar, varchar, varchar) TO public;

/*
    -- testing code
        SELECT public."udf_IndexCleanTable"('public', '_nm_cleantable', '"Rowkey1"');
        SELECT public."udf_IndexCleanTable"('public', '_nm_cleantable', '"Rowkey"');

        DROP INDEX idx__nm_cleantable_deletefilter;
        DROP INDEX idx__nm_cleantable_UriCols;
        DROP INDEX idx__nm_cleantable_type2idx;

        DROP TABLE public."_nm_cleantable";

        CREATE TABLE public."_nm_cleantable"(
         "DataPipeLineTaskQueueId" int
        ,"RowDeleted" boolean
        ,"ODS_Parent_Uri" varchar
        ,"ODS_Uri" varchar
        ,"ParentId" bigint
        ,"EffectiveStartDate" date
        ,"EffectiveEndDate" date
        ,"Rowkey" varchar);

        SELECT  *
        FROM    pg_indexes as pgi
        WHERE   pgi.schemaname = 'public'
        and     pgi.tablename  = '_nm_cleantable'
        ;
*/