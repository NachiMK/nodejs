DROP FUNCTION IF EXISTS public."udf_Drop_PreStageTables"(varchar(255));
CREATE OR REPLACE FUNCTION public."udf_Drop_PreStageTables"(TablePrefix VARCHAR(255)) 
RETURNS 
    VOID AS $$
DECLARE
    _tablename text;
BEGIN
    IF TablePrefix IS NULL OR (LENGTH(TablePrefix) = 0) THEN
        TablePrefix := '~';
    END IF;

    -- Find Tables and Drop
    FOR _tablename  IN
        SELECT quote_ident(table_schema) || '.'
            || quote_ident(table_name)      -- escape identifier and schema-qualify!
        FROM   information_schema.tables
        WHERE  table_name LIKE TablePrefix || '%'  -- your table name prefix
        AND    table_schema = 'raw'     -- exclude system schemas
    LOOP
        RAISE NOTICE '%', '-- Executing DROP TABLE IF EXISTS ' || _tablename;
        EXECUTE 'DROP TABLE IF EXISTS ' || _tablename;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM public."udf_Drop_PreStageTables"('clients');
*/
