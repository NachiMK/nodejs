CREATE OR REPLACE FUNCTION public."StringToText"(inputText TEXT, defaultToReturn TEXT default null)
RETURNS TEXT AS $$
DECLARE retVal TEXT DEFAULT NULL;
BEGIN
    BEGIN
        retVal := inputText::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid TEXT value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;