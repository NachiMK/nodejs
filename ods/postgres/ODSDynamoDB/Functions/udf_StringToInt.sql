CREATE OR REPLACE FUNCTION public."StringToInt"(inputText varchar(512), defaultToReturn int default null)
RETURNS INTEGER AS $$
DECLARE retVal INTEGER DEFAULT NULL;
BEGIN
    BEGIN
        retVal := inputText::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid integer value: "%".  Returning NULL.', inputText;
        RETURN defaultToReturn;
    END;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;