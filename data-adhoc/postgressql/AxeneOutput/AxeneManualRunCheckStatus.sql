SELECT * FROM "AxeneBatch" WHERE "ID" >= 215;

SELECT "AxeneBatchID", "FileName", "Status", "StartDate", "EndDate" 
FROM "AxeneBatchFiles" WHERE "AxeneBatchID" = 215 --IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 113)
AND "Status" != 'started'
ORDER BY "FileName"

SELECT "AxeneBatchID", "FileName", "Status", "StartDate", "EndDate" 
FROM "AxeneBatchFiles" WHERE "AxeneBatchID" = 168 --IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 215)
AND "Status" != 'started'

SELECT * FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 215);

-- Files we submitted but not in output (could be in error though)
SELECT * FROM "AxeneBatchFiles" AS AO WHERE "AxeneBatchID" = 215
AND NOT EXISTS ( SELECT * FROM "AxeneOutputValues" WHERE "AxeneBatchID" = AO."AxeneBatchID" AND "FileName" = AO."FileName");

-- Count of Files we submitted
SELECT   I."AxeneBatchID"
        ,Count(*) AS "Submitted File Count"
        ,COALESCE(MIN(O.OutputCnt), 0) AS "Output Count"
        ,COALESCE(MIN(OE."ErrorCount"), 0) AS "Error Count"
FROM    "AxeneBatchFiles" I
LEFT
JOIN    (
            SELECT  CAST(O1."BatchID" AS INT) as "AxeneBatchID"
                    ,Count(*) AS OutputCnt
            FROM    "AxeneOutputValues" AS O1
            WHERE   O1."BatchID" IN (SELECT CAST("ID" AS VARCHAR)
                                     FROM   "AxeneBatch" 
                                     WHERE "ID" >= 215) 
            GROUP  BY O1."BatchID"
        ) AS O ON O."AxeneBatchID" = I."AxeneBatchID"
LEFT
JOIN
        (
            SELECT  I1."AxeneBatchID", Count(DISTINCT I1."ID") as "ErrorCount"
            FROM    "AxenePlanBenefitErrors" AS E 
            INNER
            JOIN    "AxeneBatchFiles"        AS I1 ON I1."ID" = "AxeneBatchFileID"
            WHERE   I1."AxeneBatchID" >= 215
            GROUP   BY
                    I1."AxeneBatchID"
        ) AS OE ON OE."AxeneBatchID" = I."AxeneBatchID"
WHERE   I."AxeneBatchID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 215) 
GROUP  BY 
        I."AxeneBatchID";

-- Count Files in output
SELECT "BatchID" as "AxeneBatchID", Count(*) AS Cnt FROM "AxeneOutputValues" WHERE "BatchID" IN (SELECT CAST("ID" AS VARCHAR) FROM "AxeneBatch" WHERE "ID" >= 215) GROUP  BY "BatchID";
-- Count # of Errors by Batch
SELECT "AxeneBatchID", Count(*) as Cnt 
FROM "AxeneBatchFiles" AS I
WHERE "AxeneBatchID" = 215
AND ExISTS (SELECT * FROM "AxenePlanBenefitErrors" AS E WHERE E."AxeneBatchFileID" = I."ID")
GROUP BY
    "AxeneBatchID";
    
-- Count # of Errors by Plans
SELECT DISTINCT LEFT(REPLACE("FileName", CAST("AxeneBatchID" as VARCHAR)||'_', ''), 36) as "PlanID", Count(*) as Cnt 
FROM "AxeneBatchFiles" AS I
WHERE "AxeneBatchID" = 215
AND ExISTS (SELECT * FROM "AxenePlanBenefitErrors" AS E WHERE E."AxeneBatchFileID" = I."ID")
GROUP BY
    "AxeneBatchID", "FileName" ;

-- GET PLANS AND FOR THE ONES THAT ERRORED
SELECT  "Year", "State", "HiosPlanID" 
FROM    "Plans" 
WHERE   "Year" = 2018
AND     "State" = 'AZ'
AND     CAST("PlanID" AS VARCHAR) IN 
    (
        SELECT  DISTINCT LEFT(REPLACE("FileName", CAST("AxeneBatchID" as VARCHAR)||'_', ''), 36) as "PlanID"
        FROM    "AxeneBatchFiles" AS I
        INNER   
        JOIN    "AxenePlanBenefitErrors" AS E ON E."AxeneBatchFileID" = I."ID"
        WHERE   I."AxeneBatchID" = 215
    )
;
-- Look at actual errors
SELECT  LEFT(REPLACE("FileName", CAST("AxeneBatchID" as VARCHAR)||'_', ''), 36) as "PlanID"
        ,E.*, EL.*
FROM    "AxeneBatchFiles" AS I
INNER   
JOIN    "AxenePlanBenefitErrors" AS E ON E."AxeneBatchFileID" = I."ID"
INNER
JOIN    "AxeneErrors" AS EL ON EL."ID" = E."AxeneErrorID"
WHERE   I."AxeneBatchID" = 215
ORDER BY "PlanID", E."PlanBenefitType"

SELECT "AxeneBatchFileID", Count(*) AS Cnt FROM "AxenePlanBenefitErrors" WHERE "AxeneBatchFileID" IN (
SELECT "ID" FROM "AxeneBatchFiles" WHERE "AxeneBatchID" IN (SELECT "ID" FROM "AxeneBatch" WHERE "ID" >= 215)
) GROUP  BY "AxeneBatchFileID";


-- Plans by Error/Batch
SELECT * 
FROM "AxeneBatchFiles" I
WHERE "AxeneBatchID" = 215
AND EXISTS (SELECT * FROM "AxenePlanBenefitErrors" AS E WHERE E."AxeneBatchFileID" = I."ID")

-- distinct plans that errored
SELECT DISTINCT LEFT(REPLACE("FileName", CAST("AxeneBatchID" as VARCHAR)||'_', ''), 36) as "PlanID"
FROM "AxeneBatchFiles" I
WHERE "AxeneBatchID" = 215
AND EXISTS (SELECT * FROM "AxenePlanBenefitErrors" AS E WHERE E."AxeneBatchFileID" = I."ID")

SELECT * FROM "PlanBenefits" WHERE "HiosPlanID" = '14002TN0400001'
AND "Year" = 2019;
--AND "Benefit" like '%eligible%'
SELECT * FROM "Plans" WHERE "HiosPlanID" = '14002TN0400001' AND "Year" = 2019;
SELECT * FROM "Plans" WHERE "PlanID" = '700a4a0f-672b-422b-b2a6-4da00c08476d';
SELECT * FROM vw_PlanBenefits WHERE "HiosPlanID" = '14002TN0400001' AND "Year" = 2019;
-- Look for particular file in output
SELECT * FROM "AxeneOutputValues" WHERE "BatchID" like '215'
AND "FileName" LIKE '215_700a4a0f-672b-422b-b2a6-4da00c08476d_0_p%';

-- Look for history of changes by file
SELECT * FROM "AxeneBatchFilesHistory" 
WHERE "FileName" = '215_700a4a0f-672b-422b-b2a6-4da00c08476d_0_p'
-- "FileName" like '%301b0d8a-1d80-464c-9921-02a77a0820c5%';
ORDER BY
    "HistoryID"
;

-- Files not in error and not in output -- THESE ARE FILES Axene never returned.
SELECT DISTINCT LEFT(REPLACE("FileName", CAST("AxeneBatchID" as VARCHAR)||'_', ''), 36) as "PlanID", * 
FROM "AxeneBatchFiles" AS I
WHERE "AxeneBatchID" = 215
AND NOT EXISTS (SELECT * FROM "AxeneOutputValues" AS O WHERE "BatchID" = CAST(I."AxeneBatchID" AS VARCHAR) AND I."FileName" = O."FileName")
AND NOT ExISTS (SELECT * FROM "AxenePlanBenefitErrors" AS E WHERE E."AxeneBatchFileID" = I."ID");

SELECT * FROM public.udf_get_axenestatus(2019,'','');

SELECT * FROM public.udf_get_AxeneOutput('215')

SELECT * FROM public.udf_get_AxeneOutputErrors('215', 2019)

SELECT * FROM udf_Report_PlanBenefits(2019, 'NY') WHERE "HiosPlanID" = '14002TN0400001'

BEGIN;
SELECT * FROM udf_update_plan_av('215') as R
ROLLBACK
-- COMMIT
