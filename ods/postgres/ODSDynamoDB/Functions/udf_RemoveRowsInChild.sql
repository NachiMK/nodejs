DROP FUNCTION IF EXISTS public."udf_RemoveRowsInChild"(VARCHAR, VARCHAR, VARCHAR, TEXT, BOOLEAN);
CREATE OR REPLACE FUNCTION public."udf_RemoveRowsInChild"(CleanTableSchema VARCHAR(256)
                                                        ,CleanParentTableName VARCHAR(256)
                                                        ,PrimaryKeyName VARCHAR(256)
                                                        ,IDsToRemove TEXT DEFAULT ''
                                                        ,PrintOnlyNoDelete BOOLEAN DEFAULT false)
RETURNS VOID AS $$
    DECLARE dsql TEXT DEFAULT '';
    DECLARE UpdatedIdsToday TEXT DEFAULT '';
    DECLARE DeleteScript TEXT DEFAULT '';
BEGIN

    -- IF IDs to update is null or empty, then return back
    IF IDsToRemove IS NULL OR LENGTH(TRIM(IDsToRemove)) = 0 THEN
        RETURN;
    END IF;

    -- Find only Rows that were updated today
    dsql = '
    SELECT  STRING_AGG(CAST("' || PrimaryKeyName || '" AS VARCHAR), '','')
    FROM    ' || CleanTableSchema || '."' || CleanParentTableName || '" AS CT
    WHERE   "ODS_EffectiveEndDate" = ''9999-12-31''::DATE
    AND     EXISTS (SELECT TableId 
                    FROM regexp_split_to_table(''' || IDsToRemove || ''', '','') AS TableId 
                    WHERE CAST(TableId as BIGINT) = CT."'||PrimaryKeyName||'")
    ';
    EXECUTE dsql INTO UpdatedIdsToday;

    IF UpdatedIdsToday IS NOT NULL AND (LENGTH(UpdatedIdsToday) > 0) THEN 
        FOR DeleteScript IN
            -- Get Script to Delete All Child, Grand Child Tables.
            SELECT  'DELETE FROM ' || C."FullTableName" || 
                    ' AS C WHERE EXISTS (SELECT 1 
                                        FROM regexp_split_to_table(''' || UpdatedIdsToday || ''', '','') TableId 
                                        WHERE CAST(TableId AS BIGINT) = C."'|| C."ColumnName" ||'");' AS "ScriptToDelete"
            FROM    "vwColumnDefinition" AS P
            INNER
            JOIN    "vwColumnDefinition" AS C   ON  C."TableSchema" = P."TableSchema"
                                                AND C."TableName" != P."TableName"
                                                AND C."ColumnName" = REPLACE(P."ColumnName", 'ODS_', 'ODS_Root_')
            WHERE   P."TableName" = CleanParentTableName
            AND     P."ColumnName" = PrimaryKeyName
        LOOP
            RAISE NOTICE 'Script to Delete: %', DeleteScript;
            IF PrintOnlyNoDelete IS NULL OR PrintOnlyNoDelete = FALSE THEN
                EXECUTE DeleteScript;
            END IF;
        END LOOP;
    END IF;

    RETURN;
END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_RemoveRowsInChild"(varchar, varchar, varchar, text, boolean) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_RemoveRowsInChild"(varchar, varchar, varchar, text, boolean) TO public;

/*
    -- testing code
    SELECT public."udf_RemoveRowsInChild"('public', 'clients_clients', 'clientsId', '1,2,3');
    SELECT public."udf_RemoveRowsInChild"('public', 'clients_clients', 'clientsId', '1,2,3', false);
*/