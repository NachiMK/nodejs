DROP FUNCTION IF EXISTS public."udf_CreateIndex"(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION public."udf_CreateIndex"(userTableSchema VARCHAR(256)
                                                    , userTableName VARCHAR(256)
                                                    , userIndexName VARCHAR(256)
                                                    , IndexColNames VARCHAR(1000) )
RETURNS BOOLEAN AS $$
    DECLARE dsql TEXT DEFAULT '';
    DECLARE blnIsValid BOOLEAN DEFAULT false;
    DECLARE blnIndexExists SMALLINT DEFAULT 0;
    DECLARE blnIndexCreated BOOLEAN DEFAULT false;

    DECLARE IDXCreateStmt VARCHAR(1000) DEFAULT '';

BEGIN    

    IF LENGTH(userTableSchema) > 0 AND LENGTH(userTableName) > 0 AND 
        EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE table_name = userTableName and table_schema = userTableSchema) AND
        LENGTH(userIndexName) > 0 AND LENGTH(IndexColNames) > 0 THEN
        blnIsValid := true;
    END IF;

    -- statement to create index.
    dsql := 'CREATE INDEX ' || userIndexName || ' ON ' || userTableSchema || '."' || userTableName || '"(' || IndexColNames || ');';

    -- proceed only if valid
    IF blnIsValid THEN
        -- Check if we have created an index
        SELECT  1
        INTO    blnIndexExists 
        FROM    pg_indexes pgi
        WHERE   pgi.schemaname = userTableSchema
        and     pgi.tablename  ~* userTableName
        AND     pgi.indexname  ~* userIndexName;

        -- create index if we dont have one
        IF (blnIndexExists = 0) OR (blnIndexExists IS NULL) THEN
            -- eat any error
            BEGIN
                RAISE NOTICE 'Creating Index: "%"', dsql;
                EXECUTE dsql;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error Creating Index: "%".  Returning False.', dsql;
            END;
            -- check index created
            SELECT  true
            INTO    blnIndexCreated 
            FROM    pg_indexes as pgi
            WHERE   pgi.schemaname = userTableSchema
            and     pgi.tablename  ~* userTableName
            AND     pgi.indexname  ~* userIndexName;
        ELSE
            RAISE NOTICE 'Indxe "%" already exists, blnIndexExists %', dsql, blnIndexExists;
        END IF;
    ELSE
        RAISE NOTICE 'Invalid DB Param, Index Creation.';
    END IF;

    RETURN blnIndexCreated;
END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_CreateIndex"(VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_CreateIndex"(VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO public;
/*
    -- CREATE TABLE public."clients_clients" ("Rowkey" varchar(100))
    -- DROP TABLE public."clients_clients"
    -- DROP INDEX StgIdx_clients_clients_DeleteFilter;
    SELECT public."udf_CreateIndex"('public', 'clients_clients', 'StgIdx_clients_clients_DeleteFilter', '"Rowkey"');
*/