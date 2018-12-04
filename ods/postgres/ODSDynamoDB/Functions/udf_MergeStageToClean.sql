-- udf_MergeStageToClean
DROP FUNCTION IF EXISTS public."udf_MergeStageToClean"(jsonb);
CREATE OR REPLACE FUNCTION public."udf_MergeStageToClean"(
    MergeParams jsonb
)
RETURNS BIGINT AS $$
    DECLARE dsql TEXT DEFAULT '';
    DECLARE blnIsValid BOOLEAN DEFAULT false;
    DECLARE StageCount BIGINT DEFAULT 0;

    DECLARE CleanTblCount BIGINT DEFAULT 0;
    
    DECLARE StgTableSchema VARCHAR(256) DEFAULT '';
    DECLARE StgTableName VARCHAR(256) DEFAULT '';
    DECLARE ParentStgTableName VARCHAR(256) DEFAULT '';

    DECLARE CleanTableSchema VARCHAR(256) DEFAULT '';
    DECLARE CleanTableName VARCHAR(256) DEFAULT '';
    DECLARE CleanParentTableName VARCHAR(256) DEFAULT '';
    DECLARE PrimaryKeyName VARCHAR(256) DEFAULT '';
    DECLARE BusinessKeyColumn VARCHAR(256) DEFAULT '';
    DECLARE RootTableName VARCHAR(256) DEFAULT '';

    DECLARE UpdateCount BIGINT DEFAULT 0;
    DECLARE InsertCount BIGINT DEFAULT 0;
    DECLARE DeleteCount BIGINT DEFAULT 0;

    DECLARE UpdatedIDs TEXT DEFAULT '';
    DECLARE InsertedIDs TEXT DEFAULT '';

    DECLARE PreStageToStageTaskId BIGINT DEFAULT -1;
    DECLARE TaskQueueId BIGINT DEFAULT -1;
BEGIN
    /*
        MergeParams := 
        {
            StageTable : {
                Schema: 'stg',
                TableName: 'clients_clients',
                ParentTableName: '',
            },
            CleanTable : {
                Schema: 'public',
                TableName: 'clients_clients',
                ParentTableName: '',
                PrimaryKeyName: 'clientsId',
                BusinessKeyColumn: 'Rowkey',
                RootTableName: ''
            },
            PreStageToStageTaskId: 111,
            TaskQueueId: 112
        }
        How it works?
        - Json Schema validation is done
        - Parameters are cleaned & defaults are assigned for easy processing
        - Find Stage Row Count
        - If Stage has rows proceed or else return 0
        - Index Tables if needed so that queries run faster
            - Index Stage Table
            - Index Clean Tables
        - Find Parent Id if ParentTable is provided
        - Get all rows, Parent Id if applicable, Effective Dates
        - Merge
            - Insert (if inserting, update prior record as expired), update on conflict
            - Check if Stage has a columns called "<BusinessKeyColumn>", if so conflict should be based
                on BusinessKeyColumn, ParentId, EffectiveStartDate, EffectiveEndDate

    Root Has New Record                   -> Just Add Child, Grand Child, .....
    Root Has existing Record on New Date  -> Just Add Child, Grand Child, .....
    Root Has existing record on Same date -> Mark all existing Child as expired, Add new Childs if there are any with Root Id

    */
    SELECT public."udf_ValidateStageToCleanParams"(MergeParams)
    INTO   blnIsValid;

    /*
        -- Parameters
    */
    SELECT  "StgTableSchema"
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
    INTO     StgTableSchema
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
    FROM    public."udf_ParseMergeParams"(MergeParams);

    -- Stage has rows to merge
    dsql := 'SELECT COUNT(*) FROM ' || StgTableSchema || '.' || '"' || StgTableName || '"
    WHERE  "DataPipeLineTaskQueueId" = ' || CAST(PreStageToStageTaskId AS VARCHAR) || ';';
    EXECUTE dsql 
    INTO    StageCount;
    RAISE NOTICE 'Stage Table % Row Count: %', StgTableName, StageCount;

    IF StageCount <= 0 OR StageCount IS NULL THEN
        RAISE NOTICE 'No rows to merge from stage %, count %', StgTableName, StageCount
        USING HINT = 'Quiting process, please try table with rows';
        -- QUIT PROCESS
        RETURN 0;
    END IF;
    
    /*
        -- Index for faster access
    */
    PERFORM public."udf_IndexStageTable"(StgTableSchema, StgTableName, BusinessKeyColumn);
    PERFORM public."udf_IndexStageTable"(StgTableSchema, ParentStgTableName, BusinessKeyColumn);
    PERFORM public."udf_IndexCleanTable"(CleanTableSchema, CleanTableName, BusinessKeyColumn);
    PERFORM public."udf_IndexCleanTable"(CleanTableSchema, CleanParentTableName, BusinessKeyColumn);

    IF BusinessKeyColumn IS NOT NULL AND LENGTH(BusinessKeyColumn) > 0 THEN
        -- we dont have to find parent, because this is the parent
        -- UPDATE existing rows
        SELECT  COUNT(*) AS Cnt, STRING_AGG("TableId"::VARCHAR, ',')
        INTO    UpdateCount, UpdatedIDs
        FROM "udf_UpdateCleanTable"(
             StgTableSchema
            ,StgTableName
            ,CleanTableSchema
            ,CleanTableName
            ,PrimaryKeyName
            ,TaskQueueId
            ,PreStageToStageTaskId
            ,BusinessKeyColumn);

        -- If I am updating a row, then my child rows may get invalid
        -- Remove Child rows. Later on it will get add by its own process
        PERFORM public."udf_RemoveRowsInChild"(CleanTableSchema
                                              ,CleanTableName
                                              ,PrimaryKeyName
                                              ,UpdatedIDs);
    END IF;

    -- Add new rows
    SELECT  COUNT(*) AS Cnt, STRING_AGG("TableId"::TEXT, ',')
    INTO    InsertCount, InsertedIDs
    FROM    public."udf_InsertCleanTable"(MergeParams);

    StageCount := InsertCount + UpdateCount + DeleteCount;

    RETURN StageCount;
END;
$$ LANGUAGE plpgsql;
GRANT ALL on FUNCTION public."udf_MergeStageToClean"(jsonb) TO odsddb_role;
GRANT ALL on FUNCTION public."udf_MergeStageToClean"(jsonb) TO public;
/*
    --Testing code
    SELECT *
    FROM   public."udf_MergeStageToClean"('{"StageTable" : {
         "Schema": "stg",
         "TableName": "clients_clients",
         "ParentTableName": ""
         },
         "CleanTable" : {
            "Schema": "public",
            "TableName": "clients_clients",
            "ParentTableName": "",
            "PrimaryKeyName": "clientsId",
            "BusinessKeyColumn": "Rowkey",
            "RootTableName": ""
          },
          "PreStageToStageTaskId": 111,
          "TaskQueueId": 112}'::jsonb)
*/