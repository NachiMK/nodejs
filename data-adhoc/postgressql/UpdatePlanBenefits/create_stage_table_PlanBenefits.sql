-- SELECT * FROM public."PlanBenefits" WHERE "PlanBenefitID" = 208836;

-- DROP TABLE IF EXISTS public.stage_planbenefits_03222018;

CREATE TABLE IF NOT EXISTS public.stage_planbenefits_03222018 AS
  SELECT
       "PlanBenefitID"
      ,"Year"
      ,CAST(null as varchar(10)) as "Hios"
      ,"HiosPlanID"
      ,CAST(null as varchar(10)) as "State"
      ,"Benefit"
      ,"ServiceNotCovered"
      ,"AppliesToDeductible"
      ,"Coinsurance"
      ,"CopayAmount"
      ,"CopayDayLimit"
      ,"CoinsuranceCopayOrder"
      ,"MemberServicePaidCap"
      ,"CoverageVisitLimit"
      ,"FirstDollarVisits"
      ,"IsGrouped"
      ,"CopayAfterFirstVisits"
      ,"Notes"
      ,CAST(null as uuid) as "ClusterID"
  FROM public."PlanBenefits" WHERE 1 = 0 WITH NO DATA;

DROP VIEW IF EXISTS public.vw_stage_planbenefits;
CREATE VIEW public.vw_stage_planbenefits
  SELECT * FROM public.stage_planbenefits_03222018;

SELECT * FROM public.vw_stage_planbenefits;