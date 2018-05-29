
SELECT TRIM("HiosPlanID") as THP
        , LENGTH("HiosPlanID")
        , (SELECT Count(*) FROM "PlanBenefits" WHERE "HiosPlanID" = P."HiosPlanID" AND "Year" = P."Year") as PbCnt
        , * FROM "Plans" as P WHERE "Year" = 2018 AND EXISTS (
SELECT "HiosPlanID"
FROM    "Plans" 
WHERE   "Year" = 2018
AND     LENGTH("HiosPlanID") != LENGTH(TRIM("HiosPlanID"))
AND     TRIM("HiosPlanID") = TRIM(P."HiosPlanID")
AND     "State" = P."State"
)
ORDER BY THP



BEGIN;
UPDATE "Plans"
SET     "IsForSale" = true
        ,"UseForModeling" = true
        ,"UpdatedDate" = CURRENT_TIMESTAMP
WHERE   "HiosPlanID" = '28162OH0060061'
AND     "Year" = 2018
AND     "IsForSale" = false
;
COMMIT;

BEGIN;
DELETE FROM "Plans" WHERE CAST("PlanID" AS VARCHAR) = 'c64131cd-b95f-476f-9d80-ce7112598820' AND "HiosPlanID" LIKE '28162OH0060061 '
;
COMMIT;

BEGIN;
UPDATE "Plans"
SET    "HiosPlanID" = TRIM("HiosPlanID")
        ,"UpdatedDate" = CURRENT_TIMESTAMP
WHERE   "Year" = 2018
AND     LENGTH("HiosPlanID") != LENGTH(TRIM("HiosPlanID"))
AND     "HiosPlanID" IN
        (
         '67243LA0090005 '
        ,'67243LA0090006 '
        ,'67243LA0090007 '
        ,'67243LA0090008 '
        )
;

UPDATE "PlanBenefits"
SET    "HiosPlanID" = TRIM("HiosPlanID")
        ,"UpdatedDate" = CURRENT_TIMESTAMP
WHERE   "Year" = 2018
AND     LENGTH("HiosPlanID") != LENGTH(TRIM("HiosPlanID"))
AND     "HiosPlanID" IN
        (
         '67243LA0090005 '
        ,'67243LA0090006 '
        ,'67243LA0090007 '
        ,'67243LA0090008 '
        )
;
COMMIT;



SELECT 
	"PlanBenefitID",
     TRIM("Plans"."HiosPlanID") as THP,
     LENGTH("Plans"."HiosPlanID") as HiosLength,
	"Plans"."Year",
	"Plans"."HiosPlanID",
	"Plans"."State",
	"Benefit",
	"ServiceNotCovered",
	"AppliesToDeductible",
	"Coinsurance",
	"CopayAmount",
	"CopayDayLimit",
	"CoinsuranceCopayOrder",
	"MemberServicePaidCap",
	"CoverageVisitLimit",
	"FirstDollarVisits",
	"IsGrouped",
	"CopayAfterFirstVisits",
	"Notes",
	"Plans"."GroupID" AS "ClusterID"
	,"PlanBenefits"."UpdatedDate"
FROM "Plans"
INNER
JOIN "PlanBenefits" ON "Plans"."HiosPlanID" = "PlanBenefits"."HiosPlanID" 
                      AND "Plans"."Year" = "PlanBenefits"."Year"
                      AND "Benefit"  NOT IN 
                        ( 'MentalHealthProfessionalOutpatient'
                         ,'HabilitationServices'
                         ,'OtherPractitionerOfficeVisit'
                         ,'OutpatientRehabilitationServices'
                         ,'PreventiveCare')
WHERE "Plans"."Year" = 2018 
--AND "Plans"."IsForSale" = true 
-- AND "Benefit" IN ('EmergencyRoomFacility', 'EmergencyRoomProfessional')
AND "Plans"."State" = 'LA'
AND "Plans"."HiosPlanID"
    IN
    (
        '67243LA0090001','67243LA0090001 ','67243LA0090002 ','67243LA0090002','67243LA0090003 ','67243LA0090003','67243LA0090004 ','67243LA0090004'
    )
--AND "PlanBenefits"."CreatedDate" > CAST('2018-05-08 00:00:45' AS TIMESTAMP)
ORDER BY "HiosPlanID", HiosLength, "Benefit";

SELECT 'C' as C, * FROM "PlanRates" WHERE "HiosPlanID" IN
('67243LA0090001','67243LA0090002','67243LA0090003','67243LA0090004')
UNION ALL
SELECT 'I' as C, * FROM "PlanRates" WHERE "HiosPlanID" IN
('67243LA0090001 ','67243LA0090002 ','67243LA0090003 ','67243LA0090004 ')

BEGIN;
DELETE FROM  "PlanRates"
WHERE "HiosPlanID" IN ('67243LA0090001','67243LA0090002','67243LA0090003','67243LA0090004');

COMMIT;
--ROLLBACK;


BEGIN;
UPDATE  "PlanRates"
SET     "HiosPlanID" = TRIM("HiosPlanID"), "UpdatedDate" = CURRENT_TIMESTAMP
WHERE "HiosPlanID" IN ('67243LA0090001 ','67243LA0090002 ','67243LA0090003 ','67243LA0090004 ');

COMMIT;
--ROLLBACK;

BEGIN;

DELETE FROM "PlanBenefits" 
WHERE "HiosPlanID" IN ('67243LA0090001 ','67243LA0090002 ','67243LA0090003 ','67243LA0090004 ')
AND "Year" = 2018;


DELETE FROM "Plans" 
WHERE "HiosPlanID" IN ('67243LA0090001 ','67243LA0090002 ','67243LA0090003 ','67243LA0090004 ')
AND "State" = 'LA' AND "Year" = 2018;

COMMIT;