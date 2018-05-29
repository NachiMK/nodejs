create sequence benefits_series_override_seq
   owned by public."BenefitSeriesOverrides"."BenefitSeriesOverrideID";

alter table public."BenefitSeriesOverrides"
   alter column "BenefitSeriesOverrideID" set default nextval('benefits_series_override_seq');

commit;








create sequence benefits_seq
   owned by public."Benefits"."BenefitID";

alter table public."Benefits"
   alter column "BenefitID" set default nextval('benefits_seq');

commit;







create sequence bundle_benefits_seq
   owned by public."BundleBenefits"."BundleBenefitID";

alter table public."BundleBenefits"
   alter column "BundleBenefitID" set default nextval('bundle_benefits_seq');

commit;





create sequence locations_seq
   owned by public."Locations"."LocationID";

alter table public."Locations"
   alter column "LocationID" set default nextval('locations_seq');

commit;


    
    
create sequence plan_rates_seq
   owned by public."PlanRates"."PlanRateID";

alter table public."PlanRates"
   alter column "PlanRateID" set default nextval('plan_rates_seq');

commit;




create sequence plan_benefits_seq
   owned by public."PlanBenefits"."PlanBenefitID";

alter table public."PlanBenefits"
   alter column "PlanBenefitID" set default nextval('plan_benefits_seq');

commit;




create sequence plan_networks_seq
   owned by public."PlanNetworks"."PlanNetworkID";

alter table public."PlanNetworks"
   alter column "PlanNetworkID" set default nextval('plan_networks_seq');

commit;




create sequence plan_and_rates_2018_seq
   owned by public."PlansAndRates2018"."PlansAndRates2018ID";

alter table public."PlansAndRates2018"
   alter column "PlansAndRates2018ID" set default nextval('plan_and_rates_2018_seq');

commit;






create sequence plan_service_areas_seq
   owned by public."PlanServiceAreas"."PlanServiceAreaID";

alter table public."PlanServiceAreas"
   alter column "PlanServiceAreaID" set default nextval('plan_service_areas_seq');

commit;




