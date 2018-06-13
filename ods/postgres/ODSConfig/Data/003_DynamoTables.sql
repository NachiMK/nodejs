DROP TABLE IF EXISTS ods."DynamoTablesHelper";
CREATE TABLE IF NOT EXISTS ods."DynamoTablesHelper"
(
     "DynamoTablesHelperId" SERIAL NOT NULL PRIMARY KEY
    ,"DynamoTableName" VARCHAR(100) NOT NULL
    ,"Stage" VARCHAR(10) NOT NULL
    ,"CleanTableName" VARCHAR(100) NULL
    ,CONSTRAINT UNQ_DynamoTablesHelper UNIQUE("DynamoTableName", "Stage")
);

DELETE FROM ods."DynamoTablesHelper" WHERE "Stage" = 'prod';
INSERT INTO ods."DynamoTablesHelper" ("DynamoTableName", "Stage")
 VALUES  ('prod-application-submission-workflows', 'prod')
        ,('prod-benefit-change-events', 'prod')
        ,('prod-benefits', 'prod')
        ,('prod-bundle-event-offers-log', 'prod')
        ,('prod-carrier-messages', 'prod')
        ,('prod-cart', 'prod')
        ,('prod-client-benefits', 'prod')
        ,('prod-client-census', 'prod')
        ,('prod-client-contributions', 'prod')
        ,('prod-clients', 'prod')
        ,('prod-covered-hospitals', 'prod')
        ,('prod-doctors', 'prod')
        ,('prod-enrollment-responses', 'prod')
        ,('prod-enrollments', 'prod')
        ,('prod-locations', 'prod')
        ,('prod-models', 'prod')
        ,('prod-notes', 'prod')
        ,('prod-payroll-deductions', 'prod')
        ,('prod-persons', 'prod')
        ,('prod-persons-attributes', 'prod')
        ,('prod-prospect-census-models', 'prod')
        ,('prod-prospect-census-profiles', 'prod')
        ,('prod-prospects', 'prod')
        ,('prod-tags', 'prod')
        ,('prod-tobacco-factors-range', 'prod')
;

DELETE FROM ods."DynamoTablesHelper" WHERE "Stage" = 'int';
INSERT INTO ods."DynamoTablesHelper" ("DynamoTableName", "Stage")
 VALUES  ('int-application-submission-workflows', 'int')
        ,('int-benefit-change-events', 'int')
        ,('int-benefits', 'int')
        ,('int-bundle-event-offers-log', 'int')
        ,('int-carrier-messages', 'int')
        ,('int-cart', 'int')
        ,('int-client-benefits', 'int')
        ,('int-client-census', 'int')
        ,('int-client-contributions', 'int')
        ,('int-clients', 'int')
        ,('int-covered-hospitals', 'int')
        ,('int-doctors', 'int')
        ,('int-enrollment-responses', 'int')
        ,('int-enrollments', 'int')
        ,('int-locations', 'int')
        ,('int-models', 'int')
        ,('int-notes', 'int')
        ,('int-payroll-deductions', 'int')
        ,('int-persons', 'int')
        ,('int-persons-attributes', 'int')
        ,('int-prospect-census-models', 'int')
        ,('int-prospect-census-profiles', 'int')
        ,('int-prospects', 'int')
        ,('int-tags', 'int')
        ,('int-tobacco-factors-range', 'int')
;

DELETE FROM ods."DynamoTablesHelper" WHERE "Stage" = 'dev';
INSERT INTO ods."DynamoTablesHelper" ("DynamoTableName", "Stage")
 VALUES  ('dev-application-submission-workflows', 'dev')
        ,('dev-benefit-change-events', 'dev')
        ,('dev-benefits', 'dev')
        ,('dev-bundle-event-offers-log', 'dev')
        ,('dev-carrier-messages', 'dev')
        ,('dev-cart', 'dev')
        ,('dev-client-benefits', 'dev')
        ,('dev-client-census', 'dev')
        ,('dev-client-contributions', 'dev')
        ,('dev-clients', 'dev')
        ,('dev-covered-hospitals', 'dev')
        ,('dev-doctors', 'dev')
        ,('dev-enrollment-responses', 'dev')
        ,('dev-enrollments', 'dev')
        ,('dev-locations', 'dev')
        ,('dev-models', 'dev')
        ,('dev-notes', 'dev')
        ,('dev-payroll-deductions', 'dev')
        ,('dev-persons', 'dev')
        ,('dev-persons-attributes', 'dev')
        ,('dev-prospect-census-models', 'dev')
        ,('dev-prospect-census-profiles', 'dev')
        ,('dev-prospects', 'dev')
        ,('dev-tags', 'dev')
        ,('dev-tobacco-factors-range', 'dev')
        ,('dev-ods-persons', 'dev')
;

UPDATE  ods."DynamoTablesHelper"
SET     "CleanTableName" = REPLACE(REPLACE(REPLACE("DynamoTableName", 'prod-', ''), 'int-', ''), 'dev-', '');
