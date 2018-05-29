INSERT INTO
    public."TaskType"
    (
         "TaskTypeId"
        ,"TaskTypeDesc"
    )
SELECT   "TaskTypeId"
        ,"TaskTypeDesc"
FROM    (
                    SELECT 10 AS "TaskTypeId", 'Entry'      as "TaskTypeDesc"
            UNION   SELECT 20 AS "TaskTypeId", 'Child'      as "TaskTypeDesc"
            --UNION   SELECT 20 AS "TaskTypeId", 'postgres' as "TaskTypeDesc"
        ) AS ST
WHERE   NOT EXISTS (SELECT 1 FROM "TaskType" AS S WHERE S."TaskTypeDesc" = ST."TaskTypeDesc");

SELECT * FROM "TaskType" ORDER BY "TaskType";
