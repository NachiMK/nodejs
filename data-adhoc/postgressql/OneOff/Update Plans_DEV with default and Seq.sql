
-- This will give you "Script" that can be applied in target DB
-- to create default values for all columns that has default 
-- values
SELECT 
   table_name
  ,ordinal_position
  ,column_name
  ,data_type
  ,column_default
  ,is_nullable
  ,character_maximum_length
  ,numeric_precision
  ,'ALTER TABLE ONLY "' || table_name || '" ALTER COLUMN "' || column_name || '" SET DEFAULT ' || column_Default || ';' as "Script"
FROM information_schema.columns
WHERE table_name like 'Plan%'
AND column_default is not null
ORDER BY table_name, ordinal_position;


with table_def_seq
AS
(
SELECT
    sch.nspname AS "schema"
  , tbl.relname AS "table"
  , col.attname AS "column"
  , pg_get_expr(def.adbin, tbl.oid, true) AS "seqScript"
FROM pg_class tbl --the table
  INNER JOIN pg_namespace sch ON sch.oid = tbl.relnamespace --schema
  INNER JOIN pg_attribute col ON col.attrelid = tbl.oid --columns
  INNER JOIN pg_attrdef def ON (def.adrelid = tbl.oid AND def.adnum = col.attnum) --default values for columns
WHERE tbl.relkind = 'r' --regular relations (tables) only
      AND col.attnum > 0 --regular columns only
      AND def.adsrc LIKE 'nextval%'
)
SELECT 'ALTER TABLE ONLY "' || "table" || '" ALTER COLUMN "' || "column" || '" SET DEFAULT ' || "seqScript" || ';'
FROM   table_def_seq
; --sequences only

-- generate script to get next max value -- run in plans_prod
select string_agg('select sequence_name, last_value from "' || relname || '"', chr(13) || 'union' || chr(13) order by relname) 
from pg_class where relkind ='S'

-- script to create sequence
with cte_seq as 
(
select sequence_name, last_value from "AxeneBatchFilesHistory_HistoryID_seq"
union
select sequence_name, last_value from "AxeneBatchFiles_ID_seq"
union
select sequence_name, last_value from "AxeneBatch_ID_seq"
union
select sequence_name, last_value from "AxeneErrors_ID_seq"
union
select sequence_name, last_value from "AxeneOutputValues_ID_seq"
union
select sequence_name, last_value from "AxenePlanBenefitErrors_ID_seq"
union
select sequence_name, last_value from "PlanNotes_PlanNoteID_seq"
union
select sequence_name, last_value from "PlanNotes_PlanNoteID_seq1"
union
select sequence_name, last_value from "PlanServiceAreas_seq"
union
select sequence_name, last_value from "benefits_seq"
union
select sequence_name, last_value from "benefits_series_override_seq"
union
select sequence_name, last_value from "bundle_benefits_seq"
union
select sequence_name, last_value from "locations_seq"
union
select sequence_name, last_value from "plan_benefits_seq"
union
select sequence_name, last_value from "plan_networks_seq"
union
select sequence_name, last_value from "plan_rates_seq"
union
select sequence_name, last_value from "plan_service_areas_seq"
union
select sequence_name, last_value from "sbc_file_validations_seq"
union
select sequence_name, last_value from "stage_planrates_clean_PlanRates_StageID_seq"
union
select sequence_name, last_value from "stage_plans_av_clean_Plans_AV_StageID_seq"
)
-- take output and run in plan_dev
SELECT  'CREATE SEQUENCE IF NOT EXISTS "' || sequence_name || '" START WITH ' || CAST(last_value+1 as varchar) || ';'
FROM    cte_seq;



CREATE SEQUENCE IF NOT EXISTS "AxenePlanBenefitErrors_ID_seq" START WITH 47046;
CREATE SEQUENCE IF NOT EXISTS "bundle_benefits_seq" START WITH 78;
CREATE SEQUENCE IF NOT EXISTS "plan_benefits_seq" START WITH 660056;
CREATE SEQUENCE IF NOT EXISTS "AxeneBatchFiles_ID_seq" START WITH 367580;
CREATE SEQUENCE IF NOT EXISTS "sbc_file_validations_seq" START WITH 9010;
CREATE SEQUENCE IF NOT EXISTS "stage_plans_av_clean_Plans_AV_StageID_seq" START WITH 2825;
CREATE SEQUENCE IF NOT EXISTS "benefits_series_override_seq" START WITH 10;
CREATE SEQUENCE IF NOT EXISTS "PlanNotes_PlanNoteID_seq" START WITH 2;
CREATE SEQUENCE IF NOT EXISTS "AxeneBatchFilesHistory_HistoryID_seq" START WITH 320195;
CREATE SEQUENCE IF NOT EXISTS "AxeneBatch_ID_seq" START WITH 150;
CREATE SEQUENCE IF NOT EXISTS "AxeneOutputValues_ID_seq" START WITH 92963;
CREATE SEQUENCE IF NOT EXISTS "PlanNotes_PlanNoteID_seq1" START WITH 13510;
CREATE SEQUENCE IF NOT EXISTS "benefits_seq" START WITH 812;
CREATE SEQUENCE IF NOT EXISTS "plan_service_areas_seq" START WITH 55616;
CREATE SEQUENCE IF NOT EXISTS "locations_seq" START WITH 50052;
CREATE SEQUENCE IF NOT EXISTS "plan_rates_seq" START WITH 17537;
CREATE SEQUENCE IF NOT EXISTS "AxeneErrors_ID_seq" START WITH 41;
CREATE SEQUENCE IF NOT EXISTS "stage_planrates_clean_PlanRates_StageID_seq" START WITH 59;
CREATE SEQUENCE IF NOT EXISTS "PlanServiceAreas_seq" START WITH 2;
CREATE SEQUENCE IF NOT EXISTS "plan_networks_seq" START WITH 2;

ALTER TABLE ONLY "BenefitSeriesOverrides" ALTER COLUMN "BenefitSeriesOverrideID" SET DEFAULT nextval('benefits_series_override_seq'::regclass);
ALTER TABLE ONLY "Benefits" ALTER COLUMN "BenefitID" SET DEFAULT nextval('benefits_seq'::regclass);
ALTER TABLE ONLY "BundleBenefits" ALTER COLUMN "BundleBenefitID" SET DEFAULT nextval('bundle_benefits_seq'::regclass);
ALTER TABLE ONLY "Locations" ALTER COLUMN "LocationID" SET DEFAULT nextval('locations_seq'::regclass);
ALTER TABLE ONLY "PlanRates" ALTER COLUMN "PlanRateID" SET DEFAULT nextval('plan_rates_seq'::regclass);
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "PlanBenefitID" SET DEFAULT nextval('plan_benefits_seq'::regclass);
ALTER TABLE ONLY "PlanNetworks" ALTER COLUMN "PlanNetworkID" SET DEFAULT nextval('plan_networks_seq'::regclass);
ALTER TABLE ONLY "PlanServiceAreas" ALTER COLUMN "PlanServiceAreaID" SET DEFAULT nextval('plan_service_areas_seq'::regclass);
ALTER TABLE ONLY "SBCFileValidations" ALTER COLUMN "SBCFileValidationID" SET DEFAULT nextval('sbc_file_validations_seq'::regclass);
ALTER TABLE ONLY "PlanNotes" ALTER COLUMN "PlanNoteID" SET DEFAULT nextval('"PlanNotes_PlanNoteID_seq1"'::regclass);
ALTER TABLE ONLY "stage_plans_av_clean" ALTER COLUMN "Plans_AV_StageID" SET DEFAULT nextval('"stage_plans_av_clean_Plans_AV_StageID_seq"'::regclass);
ALTER TABLE ONLY "AxeneBatch" ALTER COLUMN "ID" SET DEFAULT nextval('"AxeneBatch_ID_seq"'::regclass);
ALTER TABLE ONLY "AxeneBatchFiles" ALTER COLUMN "ID" SET DEFAULT nextval('"AxeneBatchFiles_ID_seq"'::regclass);
ALTER TABLE ONLY "AxeneErrors" ALTER COLUMN "ID" SET DEFAULT nextval('"AxeneErrors_ID_seq"'::regclass);
ALTER TABLE ONLY "AxeneOutputValues" ALTER COLUMN "ID" SET DEFAULT nextval('"AxeneOutputValues_ID_seq"'::regclass);
ALTER TABLE ONLY "AxenePlanBenefitErrors" ALTER COLUMN "ID" SET DEFAULT nextval('"AxenePlanBenefitErrors_ID_seq"'::regclass);
ALTER TABLE ONLY "stage_planrates_clean" ALTER COLUMN "PlanRates_StageID" SET DEFAULT nextval('"stage_planrates_clean_PlanRates_StageID_seq"'::regclass);
ALTER TABLE ONLY "AxeneBatchFilesHistory" ALTER COLUMN "HistoryID" SET DEFAULT nextval('"AxeneBatchFilesHistory_HistoryID_seq"'::regclass);

ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "PlanBenefitID" SET DEFAULT nextval('plan_benefits_seq'::regclass);
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "TieredBenefit" SET DEFAULT 1;
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "SeparatedBenefit" SET DEFAULT true;
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "CopayAfterFirstVisits" SET DEFAULT '-1'::integer;
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "UpdateDate" SET DEFAULT now();
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "CopayDays" SET DEFAULT 0;
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "CreatedDate" SET DEFAULT now();
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "UpdatedDate" SET DEFAULT now();
ALTER TABLE ONLY "PlanBenefits" ALTER COLUMN "MaximumCoverage" SET DEFAULT '-1'::integer;
ALTER TABLE ONLY "PlanNetworks" ALTER COLUMN "PlanNetworkID" SET DEFAULT nextval('plan_networks_seq'::regclass);
ALTER TABLE ONLY "PlanNetworks" ALTER COLUMN "CreatedDate" SET DEFAULT now();
ALTER TABLE ONLY "PlanNetworks" ALTER COLUMN "NetworkName" SET DEFAULT false;
ALTER TABLE ONLY "PlanNetworks" ALTER COLUMN "UpdatedDate" SET DEFAULT now();
ALTER TABLE ONLY "PlanNotes" ALTER COLUMN "PlanNoteID" SET DEFAULT nextval('"PlanNotes_PlanNoteID_seq1"'::regclass);
ALTER TABLE ONLY "PlanNotes" ALTER COLUMN "CreatedDate" SET DEFAULT now();
ALTER TABLE ONLY "PlanNotes" ALTER COLUMN "UpdatedDate" SET DEFAULT now();

ALTER TABLE ONLY "PlanRates" ALTER COLUMN "PlanRateID" SET DEFAULT nextval('plan_rates_seq'::regclass);
ALTER TABLE ONLY "PlanRates" ALTER COLUMN "FourtyYearOldFactor" SET DEFAULT 1.278;
ALTER TABLE ONLY "PlanRates" ALTER COLUMN "CreatedDate" SET DEFAULT now();
ALTER TABLE ONLY "PlanRates" ALTER COLUMN "UpdatedDate" SET DEFAULT now();

ALTER TABLE ONLY "PlanServiceAreas" ALTER COLUMN "PlanServiceAreaID" SET DEFAULT nextval('plan_service_areas_seq'::regclass);
ALTER TABLE ONLY "PlanServiceAreas" ALTER COLUMN "Year" SET DEFAULT 2018;
ALTER TABLE ONLY "PlanServiceAreas" ALTER COLUMN "CreatedDate" SET DEFAULT now();
ALTER TABLE ONLY "PlanServiceAreas" ALTER COLUMN "UpdatedDate" SET DEFAULT now();