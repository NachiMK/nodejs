CREATE OR REPLACE FUNCTION public."StringToTimeStamp"(inputText character varying(512)
, defaultToReturn TIMESTAMP default null
, defaultFormat varchar(30) default 'YYYY-MM-DD hh24:mi:ss')
RETURNS TIMESTAMP AS $$
DECLARE retVal TIMESTAMP DEFAULT NULL;
BEGIN
    IF LENGTH(TRIM(inputText)) = 0 THEN
        inputText := null;
    END IF;
    BEGIN
        SELECT TO_TIMESTAMP(inputText, defaultFormat)::timestamp
        INTO retVal;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid TIMESTAMP value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

/*
SELECT public."StringToTimeStamp"('2017-11-09');
SELECT public."StringToTimeStamp"('2017-11-');
SELECT public."StringToTimeStamp"('');
SELECT public."StringToTimeStamp"(null);
SELECT public."StringToTimeStamp"('2017-11-09T17:44:37.317Z');
SELECT public."StringToTimeStamp"('2017-11-09T17:44');
SELECT public."StringToTimeStamp"('2017-11-09 17:44');
*/