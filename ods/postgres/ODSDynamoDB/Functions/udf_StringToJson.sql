CREATE OR REPLACE FUNCTION public."StringToJson"(inputText text
, defaultToReturn json default '{}'::json)
RETURNS json AS $$
    DECLARE retVal json DEFAULT NULL;
    DECLARE err_msg TEXT;
    DECLARE err_pg_detail TEXT;
    DECLARE err_hint TEXT;
    DECLARE err_stack TEXT;
BEGIN
    IF LENGTH(TRIM(inputText)) = 0 THEN
        inputText := null;
    END IF;
    BEGIN
        retVal := inputText::json;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS err_msg = MESSAGE_TEXT,
                                err_pg_detail = PG_EXCEPTION_DETAIL,
                                err_hint = PG_EXCEPTION_HINT,
                                err_stack = PG_EXCEPTION_CONTEXT;
        RAISE NOTICE 'Error : %, detail: %, hint: %, stack %', err_msg, err_pg_detail, err_hint, err_stack;
        RAISE NOTICE 'Invalid json value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

/*
SELECT public."StringToJson"('');
SELECT public."StringToJson"(null);
SELECT public."StringToJson"('{}');
SELECT public."StringToJson"('test');
SELECT public."StringToJson"('{"key":"value"}');
SELECT public."StringToJson"('{"key": { "s1": "v1" }}');
*/