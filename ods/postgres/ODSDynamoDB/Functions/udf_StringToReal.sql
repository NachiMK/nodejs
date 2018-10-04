CREATE OR REPLACE FUNCTION public."StringToReal"(inputText character varying(512)
, defaultToReturn real default null
, maxPrecision int default 22
, maxScale int default 8)
RETURNS real AS $$
    DECLARE retVal real DEFAULT NULL;
    DECLARE tempNumber NUMERIC;
    -- DECLARE numericFormat CHARACTER VARYING(512);
    DECLARE ToNumberFormat CHARACTER VARYING(512);
    DECLARE err_msg TEXT;
    DECLARE err_pg_detail TEXT;
    DECLARE err_hint TEXT;
    DECLARE err_stack TEXT;
    DECLARE dsql TEXT;
    DECLARE MAX_PRECISION INT DEFAULT 24;
    DECLARE MAX_SCALE INT DEFAULT 6;
BEGIN
    IF LENGTH(TRIM(inputText)) = 0 THEN
        inputText := null;
    END IF;
    IF maxPrecision IS NULL or maxPrecision <= 0 OR maxPrecision > MAX_PRECISION THEN
        maxPrecision := MAX_PRECISION;
    END IF;
    IF maxScale IS NULL or maxScale <= 0 OR maxScale > MAX_SCALE THEN
        maxScale := MAX_SCALE;
    END IF;
    BEGIN
        SELECT REPLACE(
                    REPLACE(
                        REPLACE(
                            REGEXP_REPLACE(inputText, '\d', '9', 'g')
                        , ',', 'G')
                    , '.', 'D')
                ,'-', 'S')
        INTO ToNumberFormat;

        SELECT to_number(inputText, ToNumberFormat)
        INTO tempNumber;

        IF maxPrecision is not null AND maxScale is not null THEN
            dsql := 'SELECT CAST( ' || CAST(tempNumber as varchar) ||  ' AS NUMERIC(' || CAST(maxPrecision as varchar) || ',' || CAST(maxScale as varchar) || '));';
            EXECUTE dsql INTO tempNumber;
            retVal := tempNumber::REAL;
        ELSE
            retVal := tempNumber::REAL;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS err_msg = MESSAGE_TEXT,
                                err_pg_detail = PG_EXCEPTION_DETAIL,
                                err_hint = PG_EXCEPTION_HINT,
                                err_stack = PG_EXCEPTION_CONTEXT;
        RAISE NOTICE 'Error : %, detail: %, hint: %, stack %', err_msg, err_pg_detail, err_hint, err_stack;
        RAISE NOTICE 'Invalid REAL value: "%".  Returning NULL.', inputText;
        RAISE NOTICE 'SQL to run: %', dsql;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

/*
SELECT public."StringToReal"('2017-11-09');
SELECT public."StringToReal"('200');
SELECT public."StringToReal"('');
SELECT public."StringToReal"(null);
SELECT public."StringToReal"('2017.1212312312');
SELECT public."StringToReal"('123123123.12131231');
SELECT public."StringToReal"('1000.00');
SELECT public."StringToReal"('10,00.00');
*/