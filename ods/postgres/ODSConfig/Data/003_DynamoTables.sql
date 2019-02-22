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
        ,('prod-bundle-event-offers', 'prod')
        ,('prod-bundle-event-offers-log', 'prod')
        ,('prod-bundle-events', 'prod')
        ,('prod-carrier-messages', 'prod')
        ,('prod-client-benefits', 'prod')
        ,('prod-client-census', 'prod')
        ,('prod-client-price-points', 'prod')
        ,('prod-clients', 'prod')
        ,('prod-enrollment-events', 'prod')
        ,('prod-enrollment-questions', 'prod')
        ,('prod-enrollment-responses', 'prod')
        ,('prod-enrollments', 'prod')
        ,('prod-locations', 'prod')
        ,('prod-modeling-census', 'prod')
        ,('prod-modeling-configuration', 'prod')
        ,('prod-modeling-group-plans', 'prod')
        ,('prod-modeling-price-points', 'prod')
        ,('prod-modeling-scenarios', 'prod')
        ,('prod-notes', 'prod')
        ,('prod-payroll-deductions', 'prod')
        ,('prod-persons', 'prod')
        ,('prod-platform-authorization-events', 'prod')
        ,('prod-prospect-census-models', 'prod')
        ,('prod-prospect-census-profiles', 'prod')
        ,('prod-prospects', 'prod')
        ,('prod-tags', 'prod')
        ,('prod-waived-benefits', 'prod')
;

DELETE FROM ods."DynamoTablesHelper" WHERE "Stage" = 'int';
INSERT INTO ods."DynamoTablesHelper" ("DynamoTableName", "Stage")
 VALUES  ('int-benefit-change-events', 'int')
        ,('int-benefits', 'int')
        ,('int-bundle-event-offers', 'int')
        ,('int-bundle-event-offers-log', 'int')
        ,('int-bundle-events', 'int')
        ,('int-carrier-messages', 'int')
        ,('int-client-benefits', 'int')
        ,('int-client-census', 'int')
        ,('int-client-price-points', 'int')
        ,('int-clients', 'int')
        ,('int-enrollment-events', 'int')
        ,('int-enrollment-questions', 'int')
        ,('int-enrollment-responses', 'int')
        ,('int-enrollments', 'int')
        ,('int-locations', 'int')
        ,('int-modeling-census', 'int')
        ,('int-modeling-configuration', 'int')
        ,('int-modeling-group-plans', 'int')
        ,('int-modeling-price-points', 'int')
        ,('int-modeling-scenarios', 'int')
        ,('int-notes', 'int')
        ,('int-persons', 'int')
        ,('int-platform-authorization-events', 'int')
        ,('int-prospect-census-models', 'int')
        ,('int-prospect-census-profiles', 'int')
        ,('int-prospects', 'int')
        ,('int-tags', 'int')
        ,('int-waived-benefits', 'int');

DELETE FROM ods."DynamoTablesHelper" WHERE "Stage" = 'dev';
INSERT INTO ods."DynamoTablesHelper" ("DynamoTableName", "Stage")
 VALUES  ('dev-benefit-change-events', 'dev')
        ,('dev-benefits', 'dev')
        ,('dev-bundle-event-offers', 'dev')
        ,('dev-bundle-event-offers-log', 'dev')
        ,('dev-bundle-events', 'dev')
        ,('dev-carrier-messages', 'dev')
        ,('dev-client-benefits', 'dev')
        ,('dev-client-census', 'dev')
        ,('dev-client-price-points', 'dev')
        ,('dev-clients', 'dev')
        ,('dev-enrollment-events', 'dev')
        ,('dev-enrollment-questions', 'dev')
        ,('dev-enrollment-responses', 'dev')
        ,('dev-enrollments', 'dev')
        ,('dev-locations', 'dev')
        ,('dev-modeling-census', 'dev')
        ,('dev-modeling-configuration', 'dev')
        ,('dev-modeling-group-plans', 'dev')
        ,('dev-modeling-price-points', 'dev')
        ,('dev-modeling-scenarios', 'dev')
        ,('dev-notes', 'dev')
        ,('dev-payroll-deductions', 'dev')
        ,('dev-persons', 'dev')
        ,('dev-platform-authorization-events', 'dev')
        ,('dev-prospect-census-models', 'dev')
        ,('dev-prospect-census-profiles', 'dev')
        ,('dev-prospects', 'dev')
        ,('dev-waived-benefits', 'dev')
;

UPDATE  ods."DynamoTablesHelper"
SET     "CleanTableName" = REPLACE(REPLACE(REPLACE("DynamoTableName", 'prod-', ''), 'int-', ''), 'dev-', '');
