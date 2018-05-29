INSERT INTO
    public."TaskStatus"
    (
         "TaskStatusId"
        ,"TaskStatusDesc"
    )
SELECT   "TaskStatusId"
        ,"TaskStatusDesc"
FROM    (
                    SELECT 10 AS "TaskStatusId", 'On Hold'             as "TaskStatusDesc"
            UNION   SELECT 20 AS "TaskStatusId", 'Ready'               as "TaskStatusDesc"
            UNION   SELECT 30 AS "TaskStatusId", 'History Captured'    as "TaskStatusDesc"
            UNION   SELECT 40 AS "TaskStatusId", 'Processing'          as "TaskStatusDesc"
            UNION   SELECT 50 AS "TaskStatusId", 'Completed'           as "TaskStatusDesc"
            UNION   SELECT 60 AS "TaskStatusId", 'Error'               as "TaskStatusDesc"
            UNION   SELECT 70 AS "TaskStatusId", 'Re-Process'          as "TaskStatusDesc"
            --UNION   SELECT 20 AS "TaskStatusId", 'postgres' as "TaskStatusDesc"
        ) AS ST
WHERE   NOT EXISTS (SELECT 1 FROM "TaskStatus" AS S WHERE S."TaskStatusDesc" = ST."TaskStatusDesc");

SELECT * FROM "TaskStatus" ORDER BY "TaskStatus";
