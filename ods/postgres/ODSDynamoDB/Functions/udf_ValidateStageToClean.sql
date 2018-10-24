-- udf_ValidateStageToClean
DROP FUNCTION IF EXISTS public."udf_ValidateStageToClean"(jsonb);
CREATE OR REPLACE FUNCTION public."udf_ValidateStageToClean"(
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

    DECLARE CleanTableSchema VARCHAR(256) DEFAULT '';
    DECLARE CleanTableName VARCHAR(256) DEFAULT '';
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
                "PrimaryKeyName": ""
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
        }
      },
      "required": [
        "Schema",
        "TableName"
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
    AND     LENGTH("TaskQueueId") > 0;

    IF blnHasColumns = false THEN
        RAISE EXCEPTION 'Invalid DB Params. One of the Stage/Clean Table values is empty --> %', blnHasColumns::text
        USING HINT = 'Please check your Stage and Clean Table Names and Schemas';
    END IF;

    WITH CTEParams
    AS
    (
    SELECT
         CAST(param->'StageTable'->>'Schema' AS VARCHAR) as "StageTableSchema"
        ,CAST(param->'StageTable'->>'TableName' AS VARCHAR) as "StageTableName"
        ,CAST(param->'CleanTable'->>'Schema' AS VARCHAR) as "CleanTableSchema"
        ,CAST(param->'CleanTable'->>'TableName' AS VARCHAR) as "CleanTableName"
    FROM (SELECT MergeParams as param) as p
    )
    SELECT  "StageTableSchema"
            ,"StageTableName"
            ,"CleanTableSchema"
            ,"CleanTableName"
    INTO     StgTableSchema
            ,StgTableName
            ,CleanTableSchema
            ,CleanTableName
    FROM    CTEParams;

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
        LEFT
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
GRANT ALL on FUNCTION public."udf_ValidateStageToClean"(jsonb) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_ValidateStageToClean"(jsonb) TO public;
/*
    --Testing code
    SELECT public."udf_ValidateStageToClean"('{"StageTable" : {
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