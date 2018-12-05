
-- Plans to terminate
SELECT "ActuarialValue", * FROM "Plans" WHERE "Year" = 2019 AND "HiosPlanID" in
(
 '36046MA0010007'
,'36046MA0010008'
,'36046MA0010009'
,'36046MA0010010'
,'36046MA0010011'
,'36046MA0010012'
,'36046MA0010013'
,'36046MA0010014'
,'36046MA0010015'
,'36046MA0010016'
,'36046MA0010017'
,'34884MA9999910'
,'34884MA9999911'
,'34884MA9999993'
,'34884MA9999994'
,'34884MA9999995'
,'34884MA9999996'
,'34884MA9999997'
,'34884MA9999998'
,'34884MA9999999'
)


BEGIN;
UPDATE "Plans" 
SET    "IsForSale" = FALSE, "PlanStatus" = 'T', "UpdatedDate" = CURRENT_TIMESTAMP, "PlanLastModified" = CURRENT_TIMESTAMP
WHERE "Year" = 2019 AND "HiosPlanID" in
(
 '36046MA0010007'
,'36046MA0010008'
,'36046MA0010009'
,'36046MA0010010'
,'36046MA0010011'
,'36046MA0010012'
,'36046MA0010013'
,'36046MA0010014'
,'36046MA0010015'
,'36046MA0010016'
,'36046MA0010017'
,'34884MA9999910'
,'34884MA9999911'
,'34884MA9999993'
,'34884MA9999994'
,'34884MA9999995'
,'34884MA9999996'
,'34884MA9999997'
,'34884MA9999998'
,'34884MA9999999'
)
COMMIT;