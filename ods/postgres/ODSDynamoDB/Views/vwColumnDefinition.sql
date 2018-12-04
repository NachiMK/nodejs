DROP VIEW IF EXISTS public."vwColumnDefinition";
CREATE OR REPLACE VIEW public."vwColumnDefinition"
AS
SELECT   PS.table_schema as "TableSchema"
        ,PS.table_name as "TableName"
        ,PS.ordinal_position as "Position"
        ,PS.column_name as "ColumnName"
        ,PS.is_nullable as "IsNullable"
        ,PS.data_type as "DataType"
        ,PS.character_maximum_length as "DataLength"
        ,PS.numeric_precision as "precision"
        ,PS.numeric_scale as "scale"
        ,CASE WHEN PS.character_maximum_length IS NOT NULL 
                THEN PS.data_type || '(' || PS.character_maximum_length || ')'
            WHEN PS.numeric_precision IS NOT NULL
            AND PS.data_type not in ('int', 'bigint', 'integer', 'smallint')
                THEN PS.data_type || '(' || CAST(PS.numeric_precision as VARCHAR) 
                        || ',' ||  CAST(PS.numeric_scale as VARCHAR) || ')'
            ELSE PS.data_type
            END as "DataTypeWithLen"
        ,PS.udt_name
        ,PS.table_schema || '."' || PS.table_name || '"' as "FullTableName"
        ,'"' || PS.column_name || '"' AS "QuotedColumnName"
FROM    INFORMATION_SCHEMA.COLUMNS PS
WHERE   table_catalog = current_database()
;
GRANT ALL PRIVILEGES on public."vwColumnDefinition" TO odsddb_role;
GRANT SELECT on public."vwColumnDefinition" TO public;
/*
    -- Testing code
    SELECT * FROM "vwColumnDefinition" 
    WHERE "TableSchema" = 'raw' and "TableName" = 'clients_54_0_clients_181002_165354'
    ORDER BY "Position"
*/