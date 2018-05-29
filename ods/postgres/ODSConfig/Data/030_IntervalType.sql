INSERT INTO
    public."IntervalType"
    (
         "IntervalTypeId"
        ,"IntervalTypeDesc"
    )
SELECT   "IntervalTypeId"
        ,"IntervalTypeDesc"
FROM    (
                    SELECT 10 AS "IntervalTypeId", 'Day'        as "IntervalTypeDesc"
            UNION   SELECT 20 AS "IntervalTypeId", 'Month'      as "IntervalTypeDesc"
            UNION   SELECT 30 AS "IntervalTypeId", 'Minute'     as "IntervalTypeDesc"
            UNION   SELECT 40 AS "IntervalTypeId", 'Seconds'    as "IntervalTypeDesc"
            UNION   SELECT 50 AS "IntervalTypeId", 'ROW_COUNT'  as "IntervalTypeDesc"
            --UNION   SELECT 20 AS "IntervalTypeId", 'postgres' as "IntervalTypeDesc"
        ) AS ST
WHERE   NOT EXISTS (SELECT 1 FROM "IntervalType" AS S WHERE S."IntervalTypeDesc" = ST."IntervalTypeDesc");

SELECT * FROM "IntervalType" ORDER BY "IntervalType";
