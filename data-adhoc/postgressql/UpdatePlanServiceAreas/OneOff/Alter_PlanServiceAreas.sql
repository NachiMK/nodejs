SELECT * FROM "PlanServiceAreas" 
WHERE  1 = 0
OR     "IssuerID" IS NULL
OR     "HiosPlanID" IS NULL
OR     "Year" IS NULL
OR     "ServiceAreaID" IS NULL
OR     "State" IS NULL
;

ALTER TABLE "PlanServiceAreas" ALTER COLUMN "IssuerID" SET NOT NULL;
ALTER TABLE "PlanServiceAreas" ALTER COLUMN "HiosPlanID" SET NOT NULL;
ALTER TABLE "PlanServiceAreas" ALTER COLUMN "Year" SET NOT NULL;
ALTER TABLE "PlanServiceAreas" ALTER COLUMN "ServiceAreaID" SET NOT NULL;
ALTER TABLE "PlanServiceAreas" ALTER COLUMN "State" SET NOT NULL;

ALTER TABLE "PlanServiceAreas" ADD CONSTRAINT UNQ_PlanServices UNIQUE ("Year", "IssuerID", "State", "ServiceAreaID", "HiosPlanID", "CountyCode", "Zipcode");