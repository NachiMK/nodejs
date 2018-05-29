CREATE SEQUENCE IF NOT EXISTS plan_service_areas_seq;
ALTER TABLE "PlanServiceAreas" ALTER COLUMN "PlanServiceAreaID" SET DEFAULT nextval('plan_service_areas_seq');
ALTER SEQUENCE plan_service_areas_seq OWNED BY "PlanServiceAreas"."PlanServiceAreaID";

CREATE SEQUENCE IF NOT EXISTS plan_benefits_seq;
ALTER TABLE "PlanBenefits" ALTER COLUMN "PlanBenefitID" SET DEFAULT nextval('plan_benefits_seq');
ALTER SEQUENCE plan_benefits_seq OWNED BY "PlanBenefits"."PlanBenefitID";

CREATE SEQUENCE IF NOT EXISTS plan_rates_seq;
ALTER TABLE "PlanRates" ALTER COLUMN "PlanRateID" SET DEFAULT nextval('plan_rates_seq');
ALTER SEQUENCE plan_rates_seq OWNED BY "PlanRates"."PlanRateID";


--PLANS_DEV
-- SELECT MAX("PlanServiceAreaID") FROM "PlanServiceAreas";
ALTER SEQUENCE IF EXISTS plan_service_areas_seq RESTART WITH 40452;
-- SELECT MAX("PlanBenefitID") FROM "PlanBenefits";
ALTER SEQUENCE IF EXISTS plan_benefits_seq RESTART WITH 510142;
-- SELECT MAX("PlanRateID") FROM "PlanRates";
ALTER SEQUENCE IF EXISTS plan_rates_seq RESTART WITH 14263;

--PLANS_INT
-- SELECT MAX("PlanServiceAreaID") FROM "PlanServiceAreas";
ALTER SEQUENCE IF EXISTS plan_service_areas_seq RESTART WITH 40453;
-- SELECT MAX("PlanBenefitID") FROM "PlanBenefits";
ALTER SEQUENCE IF EXISTS plan_benefits_seq RESTART WITH 510695;
-- SELECT MAX("PlanRateID") FROM "PlanRates";
ALTER SEQUENCE IF EXISTS plan_rates_seq RESTART WITH 14271;
