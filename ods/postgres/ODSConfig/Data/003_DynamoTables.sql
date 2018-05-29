DROP TABLE IF EXISTS public."DynamoTablesHelper";
CREATE TABLE IF NOT EXISTS public."DynamoTablesHelper"
(
     "DynamoTablesHelperId" SERIAL NOT NULL PRIMARY KEY
    ,"DynamoTableName" VARCHAR(100) NOT NULL
    ,"Stage" VARCHAR(10) NOT NULL
    ,"CleanTableName" VARCHAR(100) NULL
    ,CONSTRAINT UNQ_DynamoTablesHelper UNIQUE("DynamoTableName", "Stage")
);

DELETE FROM "DynamoTablesHelper" WHERE "Stage" = 'prod';
INSERT INTO "DynamoTablesHelper" ("DynamoTableName", "Stage")
 VALUES  ('prod-application-submission-workflows-history-v2', 'prod')
        ,('prod-benefit-change-events-history-v2', 'prod')
        ,('prod-benefits-history-v2', 'prod')
        ,('prod-bundle-event-offers-log-history-v2', 'prod')
        ,('prod-carrier-messages-history-v2', 'prod')
        ,('prod-cart-history-v2', 'prod')
        ,('prod-client-benefits-history-v2', 'prod')
        ,('prod-client-census-history-v2', 'prod')
        ,('prod-client-contributions-history-v2', 'prod')
        ,('prod-clients-history-v2', 'prod')
        ,('prod-covered-hospitals-history-v2', 'prod')
        ,('prod-doctors-history-v2', 'prod')
        ,('prod-enrollment-responses-history-v2', 'prod')
        ,('prod-enrollments-history-v2', 'prod')
        ,('prod-locations-history-v2', 'prod')
        ,('prod-models-history-v2', 'prod')
        ,('prod-notes-history-v2', 'prod')
        ,('prod-payroll-deductions-history-v2', 'prod')
        ,('prod-persons-history-v2', 'prod')
        ,('prod-persons-attributes-history-v2', 'prod')
        ,('prod-prospect-census-models-history-v2', 'prod')
        ,('prod-prospect-census-profiles-history-v2', 'prod')
        ,('prod-prospects-history-v2', 'prod')
        ,('prod-tags-history-v2', 'prod')
        ,('prod-tobacco-factors-range-history-v2', 'prod')
;

DELETE FROM "DynamoTablesHelper" WHERE "Stage" = 'int';
INSERT INTO "DynamoTablesHelper" ("DynamoTableName", "Stage")
 VALUES  ('int-application-submission-workflows-history-v2', 'int')
        ,('int-benefit-change-events-history-v2', 'int')
        ,('int-benefits-history-v2', 'int')
        ,('int-bundle-event-offers-log-history-v2', 'int')
        ,('int-carrier-messages-history-v2', 'int')
        ,('int-cart-history-v2', 'int')
        ,('int-client-benefits-history-v2', 'int')
        ,('int-client-census-history-v2', 'int')
        ,('int-client-contributions-history-v2', 'int')
        ,('int-clients-history-v2', 'int')
        ,('int-covered-hospitals-history-v2', 'int')
        ,('int-doctors-history-v2', 'int')
        ,('int-enrollment-responses-history-v2', 'int')
        ,('int-enrollments-history-v2', 'int')
        ,('int-locations-history-v2', 'int')
        ,('int-models-history-v2', 'int')
        ,('int-notes-history-v2', 'int')
        ,('int-payroll-deductions-history-v2', 'int')
        ,('int-persons-history-v2', 'int')
        ,('int-persons-attributes-history-v2', 'int')
        ,('int-prospect-census-models-history-v2', 'int')
        ,('int-prospect-census-profiles-history-v2', 'int')
        ,('int-prospects-history-v2', 'int')
        ,('int-tags-history-v2', 'int')
        ,('int-tobacco-factors-range-history-v2', 'int')
;

DELETE FROM "DynamoTablesHelper" WHERE "Stage" = 'dev';
INSERT INTO "DynamoTablesHelper" ("DynamoTableName", "Stage")
 VALUES  ('dev-application-submission-workflows-history-v2', 'dev')
        ,('dev-benefit-change-events-history-v2', 'dev')
        ,('dev-benefits-history-v2', 'dev')
        ,('dev-bundle-event-offers-log-history-v2', 'dev')
        ,('dev-carrier-messages-history-v2', 'dev')
        ,('dev-cart-history-v2', 'dev')
        ,('dev-client-benefits-history-v2', 'dev')
        ,('dev-client-census-history-v2', 'dev')
        ,('dev-client-contributions-history-v2', 'dev')
        ,('dev-clients-history-v2', 'dev')
        ,('dev-covered-hospitals-history-v2', 'dev')
        ,('dev-doctors-history-v2', 'dev')
        ,('dev-enrollment-responses-history-v2', 'dev')
        ,('dev-enrollments-history-v2', 'dev')
        ,('dev-locations-history-v2', 'dev')
        ,('dev-models-history-v2', 'dev')
        ,('dev-notes-history-v2', 'dev')
        ,('dev-payroll-deductions-history-v2', 'dev')
        ,('dev-persons-history-v2', 'dev')
        ,('dev-persons-attributes-history-v2', 'dev')
        ,('dev-prospect-census-models-history-v2', 'dev')
        ,('dev-prospect-census-profiles-history-v2', 'dev')
        ,('dev-prospects-history-v2', 'dev')
        ,('dev-tags-history-v2', 'dev')
        ,('dev-tobacco-factors-range-history-v2', 'dev')
;


UPDATE  "DynamoTablesHelper"
SET     "CleanTableName" = REPLACE(REPLACE(REPLACE(REPLACE("DynamoTableName", 'prod-', ''), 'int-', ''), 'dev-', ''), '-history-v2', '');
