SELECT * FROM "Plans" WHERE "HiosPlanID" IN (
'49831WA1920001', '49831WA1920002', '49831WA1920003', '23371WA1760002'
'23371WA1780001', '49831WA1930002', '49831WA1940001', '49831WA1940003', '49831WA1940004'
) AND "State" = 'WA' AND "Year" = 2018

CREATE TABLE TmpAVTableNaeem AS 
SELECT "State", "HiosPlanID", "ActuarialValue", "HixmeValuePlus0"
, "HixmeValuePlus500"
, "HixmeValuePlus1000"
, "HixmeValuePlus1500"
, "HixmeValuePlus2000"
, "HixmeValuePlus2500"
FROM "Plans" WHERE 1 = 0

INSERT INTO TmpAVTableNaeem SELECT 'WA', '49831WA1920001', 0.754 as "ActuarialValue", 0.834 as "HixmeValuePlus0", 0.861 as "HixmeValuePlus500", 0.886 as "HixmeValuePlus1000", 0.905 as "HixmeValuePlus1500", 0.921 as "HixmeValuePlus2000", 0.934 as "HixmeValuePlus2500";
INSERT INTO TmpAVTableNaeem SELECT 'WA', '49831WA1920002', 0.673 as "ActuarialValue", 0.798 as "HixmeValuePlus0", 0.83 as "HixmeValuePlus500", 0.856 as "HixmeValuePlus1000", 0.878 as "HixmeValuePlus1500", 0.896 as "HixmeValuePlus2000", 0.912 as "HixmeValuePlus2500";
INSERT INTO TmpAVTableNaeem SELECT 'WA', '49831WA1920003', 0.609 as "ActuarialValue", 0.76 as "HixmeValuePlus0", 0.793 as "HixmeValuePlus500", 0.82 as "HixmeValuePlus1000", 0.844 as "HixmeValuePlus1500", 0.864 as "HixmeValuePlus2000", 0.883 as "HixmeValuePlus2500";
INSERT INTO TmpAVTableNaeem SELECT 'WA', '23371WA1760002', 0.719 as "ActuarialValue", 0.828 as "HixmeValuePlus0", 0.859 as "HixmeValuePlus500", 0.883 as "HixmeValuePlus1000", 0.903 as "HixmeValuePlus1500", 0.919 as "HixmeValuePlus2000", 0.932 as "HixmeValuePlus2500";
INSERT INTO TmpAVTableNaeem SELECT 'WA', '23371WA1780001', 0.703 as "ActuarialValue", 0.818 as "HixmeValuePlus0", 0.849 as "HixmeValuePlus500", 0.873 as "HixmeValuePlus1000", 0.893 as "HixmeValuePlus1500", 0.91 as "HixmeValuePlus2000", 0.925 as "HixmeValuePlus2500";
INSERT INTO TmpAVTableNaeem SELECT 'WA', '49831WA1930002', 0.628 as "ActuarialValue", 0.748 as "HixmeValuePlus0", 0.811 as "HixmeValuePlus500", 0.839 as "HixmeValuePlus1000", 0.862 as "HixmeValuePlus1500", 0.883 as "HixmeValuePlus2000", 0.901 as "HixmeValuePlus2500";
INSERT INTO TmpAVTableNaeem SELECT 'WA', '49831WA1940001', 0.75 as "ActuarialValue", 0.83 as "HixmeValuePlus0", 0.864 as "HixmeValuePlus500", 0.889 as "HixmeValuePlus1000", 0.908 as "HixmeValuePlus1500", 0.924 as "HixmeValuePlus2000", 0.936 as "HixmeValuePlus2500";
INSERT INTO TmpAVTableNaeem SELECT 'WA', '49831WA1940003', 0.613 as "ActuarialValue", 0.765 as "HixmeValuePlus0", 0.796 as "HixmeValuePlus500", 0.823 as "HixmeValuePlus1000", 0.847 as "HixmeValuePlus1500", 0.867 as "HixmeValuePlus2000", 0.885 as "HixmeValuePlus2500";
INSERT INTO TmpAVTableNaeem SELECT 'WA', '49831WA1940004', 0.675 as "ActuarialValue", 0.8 as "HixmeValuePlus0", 0.832 as "HixmeValuePlus500", 0.858 as "HixmeValuePlus1000", 0.879 as "HixmeValuePlus1500", 0.897 as "HixmeValuePlus2000", 0.913 as "HixmeValuePlus2500";

SELECT * FROM TmpAVTableNaeem AS T
INNER JOIN "Plans" AS P ON P."State" = T."State" AND P."HiosPlanID" = T."HiosPlanID"
WHERE P."ActuarialValue" != T."ActuarialValue"
AND   P."Year" = 2018;

BEGIN;
UPDATE "Plans" AS P
SET    
 "ActuarialValue" = T."ActuarialValue"
,"HixmeValuePlus0" = T."HixmeValuePlus0"
,"HixmeValuePlus500" = T."HixmeValuePlus500"
,"HixmeValuePlus1000" = T."HixmeValuePlus1000"
,"HixmeValuePlus1500" = T."HixmeValuePlus1500"
,"HixmeValuePlus2000" = T."HixmeValuePlus2000"
, "HixmeValuePlus2500" = T."HixmeValuePlus2500"
,"UpdatedDate" = CURRENT_TIMESTAMP
,"PlanLastModified" = CURRENT_TIMESTAMP
FROM TmpAVTableNaeem AS T
WHERE P."State" = T."State" 
AND P."HiosPlanID" = T."HiosPlanID"
AND P."ActuarialValue" != T."ActuarialValue"
AND P."Year" = 2018;

COMMIT;
ROLLBACK;