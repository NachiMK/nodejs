CREATE OR REPLACE FUNCTION public."StringToTimeStampTz"(inputText character varying(512)
, defaultToReturn timestamptz default null
, defaultFormat character varying(30) default 'YYYY-MM-DD hh24:mi:ss.MS')
RETURNS timestamptz AS $$
DECLARE retVal timestamptz DEFAULT NULL;
BEGIN
    IF LENGTH(TRIM(inputText)) = 0 THEN
        inputText := null;
    END IF;
    BEGIN
        SELECT to_timestamp(inputText, defaultFormat)::timestamptz
        INTO retVal;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid timestamptz value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

/*
SELECT public."StringToTimeStampTz"('2017-11-09');
SELECT public."StringToTimeStampTz"('2017-11-');
SELECT public."StringToTimeStampTz"('');
SELECT public."StringToTimeStampTz"(null);
SELECT public."StringToTimeStampTz"('2017-11-09T17:44:37.317Z');
SELECT public."StringToTimeStampTz"('2017-11-09T17:44');
SELECT public."StringToTimeStampTz"('2017-11-09 17:44');
*/