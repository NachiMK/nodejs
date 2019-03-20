INSERT INTO
    ods."RangeType"
    (
         "RangeTypeId"
        ,"RangeTypeDesc"
    )
SELECT   "RangeTypeId"
        ,"RangeTypeDesc"
FROM    (
                    SELECT 10 AS "RangeTypeId", 'date' as "RangeTypeDesc"
            UNION   SELECT 20 AS "RangeTypeId", 'timestamp'  as "RangeTypeDesc"
            --UNION   SELECT 20 AS "RangeTypeId", 'postgres' as "RangeTypeDesc"
        ) AS ST
WHERE   NOT EXISTS (SELECT 1 FROM ods."RangeType" AS S WHERE S."RangeTypeDesc" = ST."RangeTypeDesc");

-- SELECT * FROM ods."RangeType";
