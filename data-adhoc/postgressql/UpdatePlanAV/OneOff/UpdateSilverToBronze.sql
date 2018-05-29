-- SELECT * FROM "Plans" WHERE "PlanID" = '0050d985-ac2b-4721-a50e-5efd0d1d35af';
-- SELECT * FROM pg_catalog.pg_tables WHERE tablename like 'stage_plans_av_raw%_20180418';

-- If plan is Silver, and AV is between 70 to 73 then pick corresponding Bronze plan AV & HixmeValues and update DB
SELECT  silver."PlanID"
        ,silver."HiosPlanID"
        ,silver."Year"
        ,silver."fileName" as silverFileName
        ,p."State"
        ,p."ActuarialValue"
        ,CAST(p."HixmeValuePlus0"    as varchar(20))  || ' => ' || CAST(bronze."HixmeValuePlus0"    as VARCHAR(20)) as "HixmeValuePlus0"
        ,CAST(p."HixmeValuePlus500"	 as varchar(20))  || ' => ' || CAST(bronze."HixmeValuePlus500"	as VARCHAR(20)) as "HixmeValuePlus500"
        ,CAST(p."HixmeValuePlus1000" as varchar(20))  || ' => ' || CAST(bronze."HixmeValuePlus1000" as VARCHAR(20)) as "HixmeValuePlus1000"	
        ,CAST(p."HixmeValuePlus1500" as varchar(20))  || ' => ' || CAST(bronze."HixmeValuePlus1500" as VARCHAR(20)) as "HixmeValuePlus1500"
        ,CAST(p."HixmeValuePlus2000" as varchar(20))  || ' => ' || CAST(bronze."HixmeValuePlus2000" as VARCHAR(20)) as "HixmeValuePlus2000"
        ,CAST(p."HixmeValuePlus2500" as varchar(20))  || ' => ' || CAST(bronze."HixmeValuePlus2500" as VARCHAR(20)) as "HixmeValuePlus2500"
        ,bronze."fileName" as bronzeFileName
FROM   stage_plans_av_raw_ca_rp434_20180418 as silver -- simply replace to different stage table names for other data
INNER 
JOIN   "Plans" as p  ON  CAST(p."PlanID" as VARCHAR) = silver."PlanID" 
                     AND p."Year"   = silver."Year"
                     AND p."HiosPlanID"   = silver."HiosPlanID"
INNER 
JOIN   stage_plans_av_raw_ca_rp434_20180418 as bronze   ON  bronze."PlanID"       = silver."PlanID" 
                                                        AND bronze."Year"         = silver."Year"
                                                        AND bronze."HiosPlanID"   = silver."HiosPlanID"
                                                        AND bronze."isOriginal"   = 'false'
                                                        AND bronze."fileName"     = REPLACE(silver."fileName", '_0_s', '_0_b')
WHERE silver."Metal" = 'Silver'
AND   silver."isOriginal" = 'true'
AND   silver."ActuarialValue" between 0.70 and 0.73
AND   (
        1 = 0
        OR p."HixmeValuePlus0"    != bronze."HixmeValuePlus0"   
        OR p."HixmeValuePlus500"  != bronze."HixmeValuePlus500"
        OR p."HixmeValuePlus1000" != bronze."HixmeValuePlus1000"	
        OR p."HixmeValuePlus1500" != bronze."HixmeValuePlus1500"
        OR p."HixmeValuePlus2000" != bronze."HixmeValuePlus2000"
        OR p."HixmeValuePlus2500" != bronze."HixmeValuePlus2500"
      )
;


-- update query
BEGIN; -- should run COMMIT if statement goes through fine or else run ROLLBACK
-- should update only 10 rows or else ROLLBACK
UPDATE  "Plans" p
SET     
         "HixmeValuePlus0"    = bronze."HixmeValuePlus0"   
        ,"HixmeValuePlus500"  = bronze."HixmeValuePlus500"
        ,"HixmeValuePlus1000" = bronze."HixmeValuePlus1000"	
        ,"HixmeValuePlus1500" = bronze."HixmeValuePlus1500"
        ,"HixmeValuePlus2000" = bronze."HixmeValuePlus2000"
        ,"HixmeValuePlus2500" = bronze."HixmeValuePlus2500"
        ,"UpdatedDate"        = CURRENT_TIMESTAMP
FROM   stage_plans_av_raw_ca_rp434_20180418 as silver
INNER 
JOIN   stage_plans_av_raw_ca_rp434_20180418 as bronze   ON  bronze."PlanID"       = silver."PlanID" 
                                                        AND bronze."Year"         = silver."Year"
                                                        AND bronze."HiosPlanID"   = silver."HiosPlanID"
                                                        AND bronze."isOriginal"   = 'false'
                                                        AND bronze."fileName"     = REPLACE(silver."fileName", '_0_s', '_0_b')
WHERE silver."Metal" = 'Silver'
AND   silver."isOriginal" = 'true'
AND   silver."ActuarialValue" between 0.70 and 0.73
AND   CAST(p."PlanID" as VARCHAR) = silver."PlanID" 
AND   p."Year"   = silver."Year"
AND   p."HiosPlanID"   = silver."HiosPlanID"
AND   (
        1 = 0
        OR p."HixmeValuePlus0"    != bronze."HixmeValuePlus0"   
        OR p."HixmeValuePlus500"  != bronze."HixmeValuePlus500"
        OR p."HixmeValuePlus1000" != bronze."HixmeValuePlus1000"	
        OR p."HixmeValuePlus1500" != bronze."HixmeValuePlus1500"
        OR p."HixmeValuePlus2000" != bronze."HixmeValuePlus2000"
        OR p."HixmeValuePlus2500" != bronze."HixmeValuePlus2500"
      )
;

-- COMMIT;
-- ROLLBACK;
