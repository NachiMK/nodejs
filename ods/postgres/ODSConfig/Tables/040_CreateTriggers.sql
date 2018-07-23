DROP TRIGGER IF EXISTS Trigger_DynamoTableSchema ON ods."DynamoTableSchema";
DROP FUNCTION IF EXISTS ods.trg_Capture_DynamoTableSchema();
CREATE OR REPLACE FUNCTION ods.trg_Capture_DynamoTableSchema() 
    RETURNS 
        TRIGGER AS $Trigger_DynamoTableSchema$
    BEGIN
        IF ((TG_OP = 'UPDATE')  OR (TG_OP = 'INSERT')) THEN
            INSERT INTO ods."DynamoTableSchemaHistory" 
            (
                 "RecordCreated"
                ,"DynamoTableSchemaId"
                ,"SourceEntity"
                ,"DynamoTableName"
                ,"S3JsonSchemaPath"
                ,"NextRefreshAt"
                ,"LastRefreshedDate"
                ,"DataPipeLineTaskId"
                ,"CreatedDtTm"
                ,"UpdatedDtTm"
            )
            SELECT now() as "RecordCreated", NEW.*;
            RETURN NEW;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
$Trigger_DynamoTableSchema$ LANGUAGE plpgsql;

CREATE TRIGGER Trigger_DynamoTableSchema
AFTER INSERT OR UPDATE OR DELETE ON ods."DynamoTableSchema"
    FOR EACH ROW EXECUTE PROCEDURE ods.trg_Capture_DynamoTableSchema();
