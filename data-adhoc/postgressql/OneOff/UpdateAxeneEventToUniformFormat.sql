BEGIN;

WITH AX
AS
(
SELECT "ID" 
, COALESCE("Event"->'body'->>'Year', "Event"->'query'->>'Year') as "Year"
, COALESCE("Event"->'body'->>'State', "Event"->'query'->>'State') as "State"
, COALESCE("Event"->'body'->>'PlanID', "Event"->'query'->>'PlanID') as "PlanID"
, "Event"
FROM "AxeneBatch" 
),
jsoned as
(
SELECT "ID"
    , ('{'
        || CASE WHEN "Year" IS NOT NULL THEN '"Year":"' || "Year" || '"' ELSE '' END
        || CASE WHEN "State" IS NOT NULL THEN ', "State":"' || "State" || '"' ELSE '' END
        || CASE WHEN "PlanID" IS NOT NULL THEN ', "PlanID":"' || "PlanID" || '"' ELSE '' END
        || '}')::jsonb 
        as "NewEvent"
    , "Event"
FROM   AX
)
UPDATE "AxeneBatch" AS AB
SET "Event" = J."NewEvent"
FROM jsoned as J
WHERE j."ID" = AB."ID"
AND   j."NewEvent" != AB."Event"
;

-- ROLLBACK;
COMMIT;
