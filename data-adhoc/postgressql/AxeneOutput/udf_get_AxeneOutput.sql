-- DROP FUNCTION udf_get_AxeneOutput(varchar(255));
CREATE OR REPLACE FUNCTION udf_get_AxeneOutput(batchid VARCHAR(255)) RETURNS SETOF vw_AxeneOutputFormat AS $$

    SELECT udf_create_AxeneOutputTables();

    TRUNCATE TABLE public."TempAVReport";

    WITH CTEAxeneOutput
    AS
    (
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
                ,ROW_NUMBER() OVER (PARTITION BY "FileName" ORDER BY "ID" DESC) as LatestRowNbr
        FROM    "AxeneOutputValues" AS AO
        WHERE   1 = 1
        AND     AO."BatchID" = $1
    )
    INSERT INTO
            public."TempAVReport" 
    SELECT   "ID"
            ,"fileName"
            ,"ModeledMetalTier"
            ,"PlanID"
            ,"ActuarialValue"
            ,"HixmePlusColName"
            ,"HixmePlusAddOnValue"
            ,"HixmeValue"
            ,"OriginalID"
            ,"BatchID"
    FROM    CTEAxeneOutput
    WHERE   LatestRowNbr = 1 
    ORDER   BY
            "PlanID", "ModeledMetalTier";

    WITH CTEUpdate
    AS
    (
        SELECT  "ID" 
                ,(SELECT "ID" FROM "TempAVReport" S WHERE S."ModeledMetalTier" = T."ModeledMetalTier" AND S."PlanID" = T."PlanID" AND "HixmePlusAddOnValue" = 0) as "FirstID"
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

    --DROP TABLE IF EXISTS "TempAVPivot";
    --DROP TABLE IF EXISTS "TempAVReport";
$$ LANGUAGE SQL;
/*

*/