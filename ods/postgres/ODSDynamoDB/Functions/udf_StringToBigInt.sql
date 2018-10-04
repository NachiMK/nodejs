CREATE OR REPLACE FUNCTION public."StringToBigInt"(inputText varchar(512), defaultToReturn bigint default null)
RETURNS BIGINT AS $$
DECLARE retVal BIGINT DEFAULT NULL;
BEGIN
    BEGIN
        retVal := inputText::bigint;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid bigint value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;