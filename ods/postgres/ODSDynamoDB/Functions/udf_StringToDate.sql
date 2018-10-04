CREATE OR REPLACE FUNCTION public."StringToDate"(inputText character varying(512)
, defaultToReturn TEXT default null
, defaultFormat varchar(20) default 'YYYY-MM-DD')
RETURNS DATE AS $$
DECLARE retVal DATE DEFAULT NULL;
BEGIN
    IF LENGTH(TRIM(inputText)) = 0 THEN
        inputText := null;
    END IF;
    BEGIN
        SELECT TO_DATE(inputText, defaultFormat)
        INTO retVal;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid Date value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

/*
    SELECT public."StringToDate"('2017-11-09');
    SELECT public."StringToDate"('2017-11-');
    SELECT public."StringToDate"('');
    SELECT public."StringToDate"(null);
    SELECT public."StringToDate"('2017-11-09T17:44:37.317Z');
    SELECT public."StringToDate"('2017-11-09T17:44');
    SELECT public."StringToDate"('2017-11-09 17:44');
*/