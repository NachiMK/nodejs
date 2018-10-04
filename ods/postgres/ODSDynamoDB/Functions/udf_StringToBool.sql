CREATE OR REPLACE FUNCTION public."StringToBool"(inputText varchar(512), defaultToReturn BOOLEAN default null)
RETURNS BOOLEAN AS $$
DECLARE retVal BOOLEAN DEFAULT NULL;
BEGIN
    BEGIN
        retVal := inputText::BOOLEAN;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid BOOLEAN value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;