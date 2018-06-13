-- DROP TABLE IF EXISTS public."AgeFactorType";
CREATE TABLE IF NOT EXISTS public."AgeFactorType"(
     "AgeFactorTypeID"  SERIAL          NOT NULL    PRIMARY KEY
    ,"FactorType"       VARCHAR(100)    NOT NULL
    ,"CreatedDate"      TIMESTAMP       NOT NULL    DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDate"      TIMESTAMP       NOT NULL    DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_AgeFactorType UNIQUE("FactorType")
);

INSERT INTO public."AgeFactorType"
    ("FactorType")
SELECT  "FactorType" 
FROM    (
        SELECT  CAST('Tobacco Factor' AS VARCHAR) AS "FactorType"
        ) AS C
WHERE  NOT EXISTS (SELECT 1 FROM public."AgeFactorType" AS A WHERE A."FactorType" = C."FactorType")
;

SELECT * FROM "AgeFactorType";

CREATE TABLE IF NOT EXISTS public."PlanAgeFactor"(
     "PlanAgeFactorID"   SERIAL          NOT NULL
    ,"HiosPlanID"        VARCHAR(45)     NOT NULL
    ,"Year"              INT             NOT NULL
    ,"Age"               INT             NOT NULL
    ,"AgeFactorTypeID"   INT             NOT NULL REFERENCES public."AgeFactorType"("AgeFactorTypeID")
    ,"Factor"            DECIMAL         NULL
    ,"CreatedDate"       TIMESTAMP       NOT NULL   DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDate"       TIMESTAMP       NOT NULL   DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_PlanAgeFactor UNIQUE("HiosPlanID", "Year", "Age", "AgeFactorTypeID")
    ,CONSTRAINT CHCK_PlanAgeFactor_age    CHECK ("Age" BETWEEN 0 AND 100)
);

WITH "age"
AS
(
    SELECT  "HiosPlanID", "Year", a.n as "Age"
            ,(SELECT "AgeFactorTypeID" FROM public."AgeFactorType" AS A WHERE A."FactorType" = 'Tobacco Factor') AS "AgeFactorTypeID"
    FROM    "Plans", generate_series(0, 100) as a(n)
    WHERE   "Year" IN (2018, 2019)
)
INSERT  INTO
        "PlanAgeFactor"
        (
             "HiosPlanID"
            ,"Year"
            ,"Age"
            ,"AgeFactorTypeID"
            ,"Factor"
        )
SELECT  "HiosPlanID", "Year", "Age", "AgeFactorTypeID", NULL as "Factor"
FROM    "age" AS A
WHERE   NOT EXISTS (SELECT 1 FROM "PlanAgeFactor" AS PA WHERE PA."HiosPlanID" = A."HiosPlanID"
                                                            AND PA."Year" = A."Year"
                                                            AND PA."Age" = A."Age"
                                                            AND PA."AgeFactorTypeID" = A."AgeFactorTypeID"
                    )
;

SELECT "HiosPlanID", "Year", "AgeFactorTypeID", COUNT(*) as "Cnt" FROM "PlanAgeFactor"
GROUP BY
        "HiosPlanID", "Year", "AgeFactorTypeID"
;
