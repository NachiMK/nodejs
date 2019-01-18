-- udf_ValidateStageToCleanParams
DROP FUNCTION IF EXISTS public."udf_ValidateStageToCleanParams"(jsonb);
CREATE OR REPLACE FUNCTION public."udf_ValidateStageToCleanParams"(
    MergeParams jsonb
)
RETURNS BOOLEAN AS $$
    DECLARE InvalidTypes json DEFAULT NULL;
    DECLARE schemaForParamValidation TEXT;
    DECLARE jsonSchema jsonb;
    DECLARE blnSchemaValid BOOLEAN DEFAULT false;
    DECLARE blnHasColumns BOOLEAN DEFAULT false;

    DECLARE StgTableSchema VARCHAR(256) DEFAULT '';
    DECLARE StgTableName VARCHAR(256) DEFAULT '';
    DECLARE ParentStgTableName VARCHAR(256) DEFAULT '';

    DECLARE CleanTableSchema VARCHAR(256) DEFAULT '';
    DECLARE CleanTableName VARCHAR(256) DEFAULT '';
    DECLARE CleanParentTableName VARCHAR(256) DEFAULT '';
    DECLARE PrimaryKeyName VARCHAR(256) DEFAULT '';
    DECLARE BusinessKeyColumn VARCHAR(256) DEFAULT '';
    DECLARE RootTableName VARCHAR(256) DEFAULT '';

    DECLARE PreStageToStageTaskId BIGINT DEFAULT -1;
    DECLARE TaskQueueId BIGINT DEFAULT -1;

    DECLARE ParentTblCount INT DEFAULT 0;

BEGIN
    /*
        Is MergeParams in given Format? 
        {
            "StageTable" : {
                "Schema": "stg",
                "TableName": "clients_clients",
                "ParentTableName": "",
            },
            "CleanTable" : {
                "Schema": "public",
                "TableName": "clients_clients",
                "ParentTableName": "",
                "PrimaryKeyName": "",
                "BusinessKeyColumn": ""
            },
            "PreStageToStageTaskId": 1,
            "TaskQueueId": 2
        }
    */

    schemaForParamValidation := '{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "properties": {
    "StageTable": {
      "type": "object",
      "properties": {
        "Schema": {
          "type": "string"
        },
        "TableName": {
          "type": "string"
        },
        "ParentTableName": {
          "type": "string"
        }
      },
      "required": [
        "Schema",
        "TableName"
      ]
    },
    "CleanTable": {
      "type": "object",
      "properties": {
        "Schema": {
          "type": "string"
        },
        "TableName": {
          "type": "string"
        },
        "ParentTableName": {
          "type": "string"
        },
        "PrimaryKeyName": {
          "type": "string"
        },
        "BusinessKeyColumn": {
          "type": "string"
        },
        "RootTableName": {
          "type": "string"
        }
      },
      "required": [
        "Schema",
        "TableName",
        "PrimaryKeyName"
      ]
    },
    "PreStageToStageTaskId": {
      "type": "integer"
    },
    "TaskQueueId": {
      "type": "integer"
    }
  },
  "required": [
    "StageTable",
    "CleanTable",
    "PreStageToStageTaskId",
    "TaskQueueId"
  ]
}';

    SELECT  public.validate_json_schema(schemaForParamValidation::jsonb, MergeParams, NULL)
    INTO    blnSchemaValid;

    IF blnSchemaValid = false THEN
        RAISE EXCEPTION 'Parameter is not in valid format --> %', MergeParams::text
        USING HINT = 'Please check your parameters';
    END IF;

    WITH CTEParams
    AS
    (
    SELECT
         CAST(param->'StageTable'->>'Schema' AS VARCHAR) as "StageTableSchema"
        ,CAST(param->'StageTable'->>'TableName' AS VARCHAR) as "StageTableName"
        ,CAST(param->'StageTable'->>'ParentTableName' AS VARCHAR) as "StageParentTableName"  
        ,CAST(param->'CleanTable'->>'Schema' AS VARCHAR) as "CleanTableSchema"
        ,CAST(param->'CleanTable'->>'TableName' AS VARCHAR) as "CleanTableName"
        ,CAST(param->'CleanTable'->>'PrimaryKeyName' AS VARCHAR) as "PrimaryKeyName"
        ,CAST(param->'CleanTable'->>'ParentTableName' AS VARCHAR) as "CleanParentTableName" 
        ,CAST(param->'PreStageToStageTaskId' AS VARCHAR) as "PreStageToStageTaskId"
        ,CAST(param->'TaskQueueId' AS VARCHAR) as "TaskQueueId"
    FROM (SELECT MergeParams as param) as p
    )
    SELECT  true 
    INTO    blnHasColumns
    FROM    CTEParams
    WHERE   1 = 1
    AND     LENGTH("StageTableSchema") > 0
    AND     LENGTH("StageTableName") > 0
    AND     LENGTH("CleanTableSchema") > 0
    AND     LENGTH("CleanTableName") > 0
    AND     LENGTH("PreStageToStageTaskId") > 0
    AND     LENGTH("TaskQueueId") > 0
    AND     LENGTH("PrimaryKeyName") > 0;

    IF blnHasColumns = false THEN
        RAISE EXCEPTION 'Invalid DB Params. One of the Stage/Clean Table values is empty --> %', blnHasColumns::text
        USING HINT = 'Please check your Stage and Clean Table Names and Schemas';
    END IF;

    SELECT "StgTableSchema"
          ,"StgTableName"
          ,"ParentStgTableName"
          ,"CleanTableSchema"
          ,"CleanTableName"
          ,"CleanParentTableName"
          ,"PrimaryKeyName"
          ,"BusinessKeyColumn"
          ,"RootTableName"
          ,"PreStageToStageTaskId"
          ,"TaskQueueId"
    INTO   StgTableSchema
          ,StgTableName
          ,ParentStgTableName
          ,CleanTableSchema
          ,CleanTableName
          ,CleanParentTableName
          ,PrimaryKeyName
          ,BusinessKeyColumn
          ,RootTableName
          ,PreStageToStageTaskId
          ,TaskQueueId
    FROM  public."udf_ParseMergeParams"(MergeParams);

    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = StgTableSchema AND table_name = StgTableName)
        OR NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = CleanTableSchema AND table_name = CleanTableName) THEN
        RAISE EXCEPTION 'Invalid DB Param.Stage Table % or Clean Table % doesnt exists.', StgTableName, CleanTableName
        USING HINT = 'Please check your Stage and Clean Table Names and Schemas';
    END IF;

    IF ParentStgTableName IS NOT NULL AND LENGTH(ParentStgTableName) > 0
      AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
                      WHERE table_schema = StgTableSchema AND table_name = ParentStgTableName) THEN
        RAISE EXCEPTION 'Invalid DB Param. Parent Stage Table % doesnt exists.', ParentStgTableName
        USING HINT = 'Please provide valid Parent Stage table name';
    ELSE 
      ParentTblCount := ParentTblCount + 1;
    END IF;

    IF CleanParentTableName IS NOT NULL AND LENGTH(CleanParentTableName) > 0
      AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
                      WHERE table_schema = CleanTableSchema AND table_name = CleanParentTableName) THEN
        RAISE EXCEPTION 'Invalid DB Param. Clean Parent Table % doesnt exists.', CleanParentTableName
        USING HINT = 'Please provide valid Clean Parent table name';
    ELSE
      ParentTblCount := ParentTblCount + 1;
    END IF;

    IF RootTableName IS NOT NULL AND LENGTH(RootTableName) > 0
      AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
                      WHERE table_schema = CleanTableSchema AND table_name = RootTableName) THEN
        RAISE EXCEPTION 'Invalid DB Param. Root Table % doesnt exists.', RootTableName
        USING HINT = 'Please provide valid Root table name';
    END IF;

    IF PrimaryKeyName IS NOT NULL AND LENGTH(PrimaryKeyName) > 0 
      AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                      WHERE table_schema = CleanTableSchema
                      AND table_name = CleanTableName
                      AND column_name = PrimaryKeyName) THEN
      RAISE EXCEPTION 'Invalid DB Param.Primary Key % in Clean Table % doesnt exists.', PrimaryKeyName, CleanTableName
        USING HINT = 'Please provide valid column names';
    END IF;
    
    IF BusinessKeyColumn IS NOT NULL AND LENGTH(BusinessKeyColumn) > 0 
      AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                      WHERE table_schema = CleanTableSchema
                      AND table_name = CleanTableName
                      AND column_name = BusinessKeyColumn) THEN
      RAISE EXCEPTION 'Invalid DB Param. Business Key % in Clean Table % doesnt exists.', BusinessKeyColumn, CleanTableName
        USING HINT = 'Please provide valid column names';
    END IF;

    IF NOT (((LENGTH(CleanParentTableName) > 0) AND (LENGTH(ParentStgTableName) > 0))
            OR (LENGTH(BusinessKeyColumn) > 0)) THEN
      RAISE EXCEPTION 'Invalid DB Param. Either CleanParentTableName: % & StageParentTableName: % 
                      should be provided or Business Key: % should be provided.'
                      , CleanParentTableName, ParentStgTableName, BusinessKeyColumn;
    END IF;
    
    WITH CTEPublicSchema
    AS
    (
        SELECT   PS."Position"
                ,PS."ColumnName"
                ,PS."IsNullable"
                ,PS."DataType"
                ,PS."DataLength"
                ,PS."precision"
                ,PS."scale"
                ,PS."DataTypeWithLen"
                ,PS.udt_name
        FROM    public."vwColumnDefinition" as PS
        WHERE   PS."TableSchema" = CleanTableSchema
        AND     PS."TableName" = CleanTableName
    ),
    CTEStageSchema
    AS
    (
        SELECT   PS."Position"
                ,PS."ColumnName"
                ,PS."IsNullable"
                ,PS."DataType"
                ,PS."DataLength"
                ,PS."precision"
                ,PS."scale"
                ,PS."DataTypeWithLen"
                ,PS.udt_name
        FROM    public."vwColumnDefinition" as PS
        WHERE   PS."TableSchema" = StgTableSchema
        AND     PS."TableName" = StgTableName
    )
    -- check if we dont have conversion functions, if so throw error
    SELECT array_to_json(array_agg(t))
    INTO   InvalidTypes
    FROM   (
        SELECT  C."DataType" as "CleanType", S."DataType" as "StageType", COUNT(*) as "Cnt"
        FROM    CTEPublicSchema C
        INNER
        JOIN    CTEStageSchema  S ON S."ColumnName" = C."ColumnName"
        WHERE   (s."ColumnName" !~ 'StgId')
        AND NOT EXISTS (SELECT * FROM public."CastFunctionMapping" CF 
                    WHERE UPPER(CF."SourceType") = UPPER(S."DataType")
                    AND   UPPER(CF."TargetType") = UPPER(C."DataType")
                    )
        AND     C."DataType" != S."DataType"
        GROUP BY C."DataType", S."DataType"
    ) t;
    
    IF InvalidTypes IS NOT NULL THEN
        RAISE EXCEPTION 'Some Stage Types cannot be converted --> %', InvalidTypes::text
        USING HINT = 'Please check your Stage data table types and Clean Table Data Types';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_ValidateStageToCleanParams"(jsonb) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_ValidateStageToCleanParams"(jsonb) TO public;
/*
    --Testing code
    SELECT public."udf_ValidateStageToCleanParams"('{"StageTable" : {
         "Schema": "stg",
         "TableName": "clients_clients",
         "ParentTableName": ""
         },
         "CleanTable" : {
            "Schema": "public",
            "TableName": "clients_clients",
            "ParentTableName": "",
            "PrimaryKeyName": ""
          },
          "PreStageToStageTaskId": 1,
          "TaskQueueId": 2}'::jsonb)

*/
