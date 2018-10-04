CREATE OR REPLACE FUNCTION public."StringToJsonb"(inputText text
, defaultToReturn jsonb default '{}'::jsonb)
RETURNS jsonb AS $$
    DECLARE retVal jsonb DEFAULT NULL;
    DECLARE err_msg TEXT;
    DECLARE err_pg_detail TEXT;
    DECLARE err_hint TEXT;
    DECLARE err_stack TEXT;
BEGIN
    IF LENGTH(TRIM(inputText)) = 0 THEN
        inputText := null;
    END IF;
    BEGIN
        retVal := inputText::jsonb;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS err_msg = MESSAGE_TEXT,
                                err_pg_detail = PG_EXCEPTION_DETAIL,
                                err_hint = PG_EXCEPTION_HINT,
                                err_stack = PG_EXCEPTION_CONTEXT;
        RAISE NOTICE 'Error : %, detail: %, hint: %, stack %', err_msg, err_pg_detail, err_hint, err_stack;
        RAISE NOTICE 'Invalid jsonb value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

/*
SELECT public."StringToJsonb"('');
SELECT public."StringToJsonb"(null);
SELECT public."StringToJsonb"('{}');
SELECT public."StringToJsonb"('test');
SELECT public."StringToJsonb"('{"key":"value"}');
SELECT public."StringToJsonb"('{"key": { "s1": "v1" }}');
*/