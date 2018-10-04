WITH CTEFuncs
AS
(

    SELECT 'character varying' as "SourceType", 'timestamp with time zone' as "TargetType", 'StringToTimeStampTz' as "CastFunction"
    UNION SELECT 'character varying', 'timestamp without time zone', 'StringToTimeStamp'
    UNION SELECT 'character varying', 'date', 'StringToDate'
    UNION SELECT 'character varying', 'bool', 'StringToBool'
    UNION SELECT 'character varying', 'boolean', 'StringToBool'
    UNION SELECT 'character varying', 'text', 'StringToText'
    UNION SELECT 'character varying', 'json', 'StringToJson'
    UNION SELECT 'character varying', 'jsonb', 'StringToJsonB'
    UNION SELECT 'text', 'json', 'StringToJson'
    UNION SELECT 'text', 'jsonb', 'StringToJsonb'
    UNION SELECT 'character varying', 'integer', 'StringToInt'
    UNION SELECT 'character varying', 'bigint', 'StringToInt'
    UNION SELECT 'character varying', 'numeric', 'StringToNumeric'
    UNION SELECT 'character varying', 'decimal', 'StringToDecimal'
    UNION SELECT 'character varying', 'float', 'StringToFloat'
    UNION SELECT 'character varying', 'double precision', 'StringToDouble'

)
INSERT INTO
    public."CastFunctionMapping"
    (
         "SourceType"
        ,"TargetType"
        ,"CastFunction"
    )
SELECT   T."SourceType"
        ,T."TargetType"
        ,T."CastFunction"
FROM    CTEFuncs AS T
WHERE   NOT EXISTS (SELECT 1 FROM "CastFunctionMapping" AS C
                    WHERE C."SourceType" = T."SourceType"
                    AND   C."TargetType" = T."TargetType")
;