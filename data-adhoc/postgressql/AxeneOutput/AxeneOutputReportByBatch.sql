SELECT * FROM "AxeneBatch";

SELECT * FROM "AxeneBatchFiles" WHERE "AxeneBatchID" = 71 AND "EndDate" is not null;
SELECT * FROM "AxeneBatchFiles" WHERE "AxeneBatchID" = 71 AND "EndDate" is null;

--BEGIN;
--DELETE FROM "AxeneBatchFiles" WHERE "AxeneBatchID" > 2;
--DELETE FROM "AxeneBatch" WHERE "ID" > 2;
--COMMIT;

SELECT COUNT(*) FROM "AxeneBatchFiles" WHERE "AxeneBatchID" = 71 and "EndDate" is not null;
SELECT COUNT(*) FROM "AxeneBatchFiles" WHERE "AxeneBatchID" = 71 and "EndDate" is null;

SELECT * FROM "AxeneErrors"

SELECT * 
FROM    "AxenePlanBenefitErrors" AS APE 
INNER
JOIN    "AxeneBatchFiles" as AB ON AB."ID" = APE."AxeneBatchFileID"
WHERE   AB."AxeneBatchID" = 73;


-- script to reupload files from INput folder to Axene S3 bucket
SELECT 'aws s3 cp ' || "FileName" || '.json s3://hixme-batch-process-datasets-315363678205-us-west-2/input/ --acl bucket-owner-full-control'
FROM    "AxenePlanBenefitErrors" AS APE 
INNER
JOIN    "AxeneBatchFiles" as AB ON AB."ID" = APE."AxeneBatchFileID"
WHERE   AB."AxeneBatchID" = 72;

-- script to upload output files that we donwloaded from axene to our input bucket for processing AV
SELECT 'aws s3 cp ' || "FileName" || '.json s3://prod-axene-digest/'
FROM    "AxenePlanBenefitErrors" AS APE 
INNER
JOIN    "AxeneBatchFiles" as AB ON AB."ID" = APE."AxeneBatchFileID"
WHERE   AB."AxeneBatchID" = 70;

SELECT "BatchID", COUNT(*) FROM "AxeneOutputValues" GROUP BY "BatchID" ORDER BY "BatchID";

SELECT * FROM "AxeneOutputValues" WHERE "BatchID" = '73';
SELECT "FileName", COUNT(*) FROM "AxeneOutputValues" WHERE "BatchID" = '73' GROUP BY "FileName" HAVING COUNT(*) > 1;

SELECT * FROM "AxeneOutputValues" WHERE "BatchID" = '73' 
AND "FileName" IN
(
    SELECT "FileName" FROM "AxeneOutputValues" WHERE "BatchID" = '73' GROUP BY "FileName" HAVING COUNT(*) > 1
);
SELECT * FROM "AxeneOutputValues" WHERE "BatchID" = '2' AND "PlanID" = '4fe2562a-3ac9-49ce-a3ac-10d67436af24';

-- Find if the new files we reuploaded got processed
SELECT  *
FROM    "AxeneOutputValues"
WHERE   "BatchID" = '72'
AND     "FileName" IN (
                SELECT  "FileName"
                FROM    "AxenePlanBenefitErrors" AS APE 
                INNER
                JOIN    "AxeneBatchFiles" as AB ON AB."ID" = APE."AxeneBatchFileID"
                WHERE   AB."AxeneBatchID" = 72
            )
;


SELECT * FROM TempAVReport AS T WHERE "PlanID" = '02221b2c-d9ea-433e-9d98-594753295310' AND "ModeledMetalTier" = 'b'; 
SELECT * FROM TempAVPivot  WHERE "OriginalID" = 434

DROP TABLE IF EXISTS TempAVReport;
CREATE TEMPORARY TABLE TempAVReport AS 
SELECT   AO."ID"
        ,"FileName" as "fileName"
        ,AO."ModeledMetalTier"
        ,AO."PlanID"
        ,AO."ActuarialValue"
        ,'HixmeValuePlus' || REPLACE(REPLACE(REPLACE(RIGHT("FileName", LENGTH("FileName")-(LENGTH("BatchID")+1)), AO."PlanID", ''), AO."ModeledMetalTier", ''), '_', '') as "HixmePlusColName"
        ,CAST(REPLACE(REPLACE(REPLACE(RIGHT("FileName", LENGTH("FileName")-(LENGTH("BatchID")+1)), AO."PlanID", ''), AO."ModeledMetalTier", ''), '_', '') AS NUMERIC) as "HixmePlusAddOnValue"
        ,AO."HixmeValue"
        ,CAST(NULL AS INT) as "RowSeq"
        ,CAST(NULL AS INT) AS "OriginalID"
        ,"BatchID"
FROM    "AxeneOutputValues" AS AO
WHERE   1 = 1
AND     AO."BatchID" = '71'
--AND     AO."PlanID" = '4fe2562a-3ac9-49ce-a3ac-10d67436af24'
ORDER   BY
        AO."PlanID", AO."ModeledMetalTier";

WITH CTEUpdate
AS
(
SELECT  "ID" 
        ,ROW_NUMBER() OVER (PARTITION BY "PlanID", "ModeledMetalTier" ORDER BY "HixmePlusAddOnValue") as RS
        ,(SELECT "ID" FROM TempAVReport S WHERE S."ModeledMetalTier" = T."ModeledMetalTier" AND S."PlanID" = T."PlanID" AND "HixmePlusAddOnValue" = 0) as "FirstID"
FROM    TempAVReport AS T
)
UPDATE  TempAVReport AS A
SET     "RowSeq" = RS
        ,"OriginalID" = "FirstID"
FROM    CTEUpdate AS C
WHERE   C."ID" = A."ID"
AND     A."RowSeq" IS NULL;


DROP TABLE IF EXISTS TempAVPivot;
CREATE TEMPORARY TABLE TempAVPivot AS 
SELECT * 
FROM    crosstab( 'SELECT "OriginalID", "HixmePlusAddOnValue", "HixmeValue" from TempAVReport order by 1,2') 
            AS final_result("OriginalID" INT
                            , "0" NUMERIC
                            , "500" NUMERIC
                            , "1000" NUMERIC
                            , "1500" NUMERIC
                            , "2000" NUMERIC
                            , "2500" NUMERIC)
;

-- Report
SELECT  CASE WHEN FP."MetalFirstChar" = T."ModeledMetalTier" THEN 'TRUE' ELSE 'FALSE' END AS "isOriginal"
        ,RIGHT(T."fileName", LENGTH(T."fileName")-LENGTH(T."BatchID")-1) as "fileName"
        ,FP."Year"
        ,FP."HiosPlanID"
        ,FP."PlanMarketingName"
        ,FP."State"
        ,FP."Carrier"
        ,FP."PlanType"
        ,FP."Metal"
        ,FP."IsHSA"
        ,FP."IsActive"
        ,FP."IsForSale"
        ,FP."IsApproved"
        ,FP."UseForModeling"
        ,T."PlanID"
        ,FP."GroupID"
        ,T."ActuarialValue"
        ,C."0" AS "HixmeValuePlus0"
        ,C."500" AS "HixmeValuePlus500"
        ,C."1000" AS "HixmeValuePlus1000"
        ,C."1500" AS "HixmeValuePlus1500"
        ,C."2000" AS "HixmeValuePlus2000"
        ,C."2500" AS "HixmeValuePlus2500"
FROM    TempAVReport    T
INNER
JOIN    TempAVPivot AS C ON C."OriginalID" = T."ID"
INNER
JOIN    LATERAL
        (
                SELECT   p."Year"
                        ,p."HiosPlanID"
                        ,p."PlanMarketingName"
                        ,p."State"
                        ,p."Carrier"
                        ,p."PlanType"
                        ,p."Metal"
                        ,CASE WHEN LOWER(LEFT(p."Metal", 1)) = 'c' THEN 'b' ELSE LOWER(LEFT(p."Metal", 1)) END as "MetalFirstChar"
                        ,CAST(p."IsHSA" as VARCHAR(5)) AS "IsHSA"
                        ,CAST(p."IsActive" as VARCHAR(5)) AS "IsActive"
                        ,CAST(p."IsForSale" as VARCHAR(5)) AS "IsForSale"
                        ,CAST(p."IsApproved" as VARCHAR(5)) AS "IsApproved"
                        ,CAST(p."UseForModeling" as VARCHAR(5)) AS "UseForModeling"
                        ,p."GroupID"
                FROM    "Plans" AS P
                WHERE   CAST(P."PlanID" AS VARCHAR) = T."PlanID"
        ) AS FP ON true
ORDER BY
        "State", "HiosPlanID", "isOriginal" desc, "fileName"
;


SELECT * FROM public.vw_AxeneOutputFormat


SELECT "State", Count(*) 
FROM  "Plans"
WHERE "Year" = 2018
GROUP BY
    "State"
ORDER BY 2 asc;

-- Axene Output Report
TRUNCATE TABLE public."TempAVReport";

    INSERT INTO
            public."TempAVReport" 
    SELECT   AO."ID"
            ,"FileName" as "fileName"
            ,AO."ModeledMetalTier"
            ,AO."PlanID"
            ,AO."ActuarialValue"
            ,'HixmeValuePlus' || REPLACE(REPLACE(REPLACE(RIGHT("FileName", LENGTH("FileName")-(LENGTH("BatchID")+1)), AO."PlanID", ''), AO."ModeledMetalTier", ''), '_', '') as "HixmePlusColName"
            ,CAST(REPLACE(REPLACE(REPLACE(RIGHT("FileName", LENGTH("FileName")-(LENGTH("BatchID")+1)), AO."PlanID", ''), AO."ModeledMetalTier", ''), '_', '') AS NUMERIC) as "HixmePlusAddOnValue"
            ,AO."HixmeValue"
            ,CAST(NULL AS INT) AS "OriginalID"
            ,"BatchID"
    FROM    "AxeneOutputValues" AS AO
    WHERE   1 = 1
    AND     AO."BatchID" = '73'
    ORDER   BY
            AO."PlanID", AO."ModeledMetalTier";

    WITH CTEUpdate
    AS
    (
        SELECT  "ID" 
                ,(SELECT MIN("ID") FROM "TempAVReport" S WHERE S."ModeledMetalTier" = T."ModeledMetalTier" AND S."PlanID" = T."PlanID" AND "HixmePlusAddOnValue" = 0) as "FirstID"
        FROM    "TempAVReport" AS T
    )
    UPDATE  "TempAVReport" AS A
    SET     "OriginalID" = "FirstID"
    FROM    CTEUpdate AS C
    WHERE   C."ID" = A."ID"
    AND     A."OriginalID" IS NULL;


    TRUNCATE TABLE public."TempAVPivot";
    INSERT INTO public."TempAVPivot" 
    SELECT * 
    FROM   crosstab( 'SELECT "OriginalID", "HixmePlusAddOnValue", "HixmeValue" from "TempAVReport" order by 1,2') 
               AS final_result("OriginalID" INT
                                , "0" NUMERIC
                                , "500" NUMERIC
                                , "1000" NUMERIC
                                , "1500" NUMERIC
                                , "2000" NUMERIC
                                , "2500" NUMERIC)
    ;

    -- Report
    SELECT  CASE WHEN FP."MetalFirstChar" = T."ModeledMetalTier" THEN 'TRUE' ELSE 'FALSE' END AS "isOriginal"
            ,RIGHT(T."fileName", LENGTH(T."fileName")-LENGTH(T."BatchID")-1) as "fileName"
            ,FP."Year"
            ,FP."HiosPlanID"
            ,FP."PlanMarketingName"
            ,FP."State"
            ,FP."Carrier"
            ,FP."PlanType"
            ,FP."Metal"
            ,FP."IsHSA"
            ,FP."IsActive"
            ,FP."IsForSale"
            ,FP."IsApproved"
            ,FP."UseForModeling"
            ,FP."PlanID"
            ,FP."GroupID"
            ,T."ActuarialValue"
            ,C."0" AS "HixmeValuePlus0"
            ,C."500" AS "HixmeValuePlus500"
            ,C."1000" AS "HixmeValuePlus1000"
            ,C."1500" AS "HixmeValuePlus1500"
            ,C."2000" AS "HixmeValuePlus2000"
            ,C."2500" AS "HixmeValuePlus2500"
    FROM    public."TempAVReport"    T
    INNER
    JOIN    public."TempAVPivot" AS C ON C."OriginalID" = T."ID"
    INNER
    JOIN    LATERAL
            (
                    SELECT   p."Year"
                            ,p."HiosPlanID"
                            ,p."PlanMarketingName"
                            ,p."State"
                            ,p."Carrier"
                            ,p."PlanType"
                            ,p."Metal"
                            ,CASE WHEN LOWER(LEFT(p."Metal", 1)) = 'c' THEN 'b' ELSE LOWER(LEFT(p."Metal", 1)) END as "MetalFirstChar"
                            ,CAST(p."IsHSA" as VARCHAR(5)) AS "IsHSA"
                            ,CAST(p."IsActive" as VARCHAR(5)) AS "IsActive"
                            ,CAST(p."IsForSale" as VARCHAR(5)) AS "IsForSale"
                            ,CAST(p."IsApproved" as VARCHAR(5)) AS "IsApproved"
                            ,CAST(p."UseForModeling" as VARCHAR(5)) AS "UseForModeling"
                            ,p."GroupID"
                            ,p."PlanID"
                    FROM    "Plans" AS P
                    WHERE   CAST(P."PlanID" AS VARCHAR) = T."PlanID"
            ) AS FP ON true
    ORDER BY
            "State", "HiosPlanID", "isOriginal" desc, "fileName"
    ;


-- Error Report
SELECT  FP."Year"
        ,FP."HiosPlanID"
        ,FP."PlanMarketingName"
        ,FP."State"
        ,FP."Carrier"
        ,FP."PlanType"
        ,FP."Metal"
        ,FP."IsHSA"
        ,FP."IsActive"
        ,FP."IsForSale"
        ,FP."IsApproved"
        ,FP."UseForModeling"
        ,FP."PlanID"
        ,FP."GroupID"
        ,AF."FileName"
        ,AF."Status"
        ,AE."CategoryName"
        ,AE."CategoryDescription"
        ,AE."RuleName"
        ,AE."RuleDescription"
        --,"PlanBenefitType"
        ,AF."AxeneBatchID"
        ,ABE."AxeneBatchFileID"
    FROM    "AxenePlanBenefitErrors" ABE
    INNER
    JOIN    "AxeneBatchFiles" AF ON AF."ID" = ABE."AxeneBatchFileID" 
    LEFT
    JOIN    "AxeneErrors" AS AE ON AE."ID"  = ABE."AxeneErrorID"
    LEFT
    JOIN    LATERAL
            (
                    SELECT   p."Year"
                            ,p."HiosPlanID"
                            ,p."PlanMarketingName"
                            ,p."State"
                            ,p."Carrier"
                            ,p."PlanType"
                            ,p."Metal"
                            ,CASE WHEN LOWER(LEFT(p."Metal", 1)) = 'c' THEN 'b' ELSE LOWER(LEFT(p."Metal", 1)) END as "MetalFirstChar"
                            ,CAST(p."IsHSA" as VARCHAR(5)) AS "IsHSA"
                            ,CAST(p."IsActive" as VARCHAR(5)) AS "IsActive"
                            ,CAST(p."IsForSale" as VARCHAR(5)) AS "IsForSale"
                            ,CAST(p."IsApproved" as VARCHAR(5)) AS "IsApproved"
                            ,CAST(p."UseForModeling" as VARCHAR(5)) AS "UseForModeling"
                            ,p."GroupID"
                            ,p."PlanID"
                    FROM    "Plans" AS P
                    WHERE   LEFT(REPLACE(AF."FileName", AF."AxeneBatchID" || '_', ''), 36) LIKE CAST(P."PlanID" AS VARCHAR)
                    AND     p."Year" = 2018
            ) AS FP ON true
WHERE   "AxeneBatchID" IN ('73')
AND     "Status" = 'error'
ORDER BY
        AF."AxeneBatchID", "PlanID", "FileName", "CategoryName", "RuleName"
;


SELECT * FROM "Plans"