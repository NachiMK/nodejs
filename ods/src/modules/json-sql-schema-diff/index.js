import isEmpty from 'lodash/isEmpty'
import forEach from 'lodash/forEach'
import isUndefined from 'lodash/isUndefined'
import size from 'lodash/size'
import isObject from 'lodash/isObject'
import { ExtractMatchingKeyFromSchema } from '../json-extract-matching-keys/index'
import { KnexTable } from '../../data/psql/table/knexTable'
import { IsValidString } from '../../utils/string-utils'
import { IsValidBoolean } from '../../utils/bool-utils'
import {
  GetNewType,
  DataTypeTransferEnum,
  JsonPostgreTypeMappingEnum,
  IsValidTypeObject,
  GetCleanColumnName,
} from '../../data/psql/DataTypeTransform'

/**
 * @class SchemaDiff
 * @classdesc SchemaDiff find difference between a JSON
 * schema and a SQL table schema
 * @constructor Takes in
 *  Json Schema,
 *  Table Name,
 *  Schema Name,
 *  Which key in Json Schema should be used for finding data types of Json fields
 *  DB Connection (only postgresl is supported)
 */
export class SchemaDiff {
  constructor(params) {
    this._jsonSchema = params.JsonSchema || {}
    this._tableName = params.TableName || ''
    this._tableSchema = params.TableSchema || 'public'
    this._dataTypeKey = params.DataTypeKey || 'db_type'
    this._hadNestedProperties = params.HadNestedProperties || false
    this._dbConnection = params.DBConnection || ''
    this._dbTypesFromJson = undefined
  }
  get JsonSchema() {
    return this._jsonSchema
  }
  get TableName() {
    return this._tableName
  }
  get TableSchema() {
    return this._tableSchema
  }
  get DBConnection() {
    return this._dbConnection
  }
  get DataTypeFromSchema() {
    return this._dbTypesFromJson
  }
  get DataTypeKey() {
    return this._dataTypeKey
  }
  get HadNestedProperties() {
    return this._hadNestedProperties
  }

  async TableExists() {
    let blnRet = false
    const objKnex = new KnexTable({
      ConnectionString: this.DBConnection,
      TableName: this.TableName,
      TableSchema: this.TableSchema,
    })
    blnRet = await objKnex.TableExists()
    return blnRet
  }

  /**
   * @member JsonColumnsAndTypes
   * Dont call this Method without properly initiating the class
   * it is not meant for public use.
   */
  JsonColumnsAndTypes() {
    if (this.JsonSchema && this.DataTypeKey) {
      const colsAndTypes = ExtractMatchingKeyFromSchema(this.JsonSchema, this.DataTypeKey, {
        IncludeMaxLength: true,
        SkipObjectsAndArrays: true,
      })
      return colsAndTypes
    } else {
      throw new Error(`Invalid Parameters. Json Schema and/or Data Type Key is missing.`)
    }
  }

  /**
   * @function TableSchemaToJson
   * This function gets Table schema from Database
   * The schema is in JSON format (NOT JSON Schema format)
   *
   * IF provided table doesn't exists
   * then an empty object is returned.
   *
   * @throws DBConnection errors or Permission errors.
   */
  async TableSchemaToJson() {
    const blnExists = await this.TableExists()
    if (blnExists) {
      // get table schema
      const objKnex = new KnexTable({
        TableName: this.TableName,
        TableSchema: this.TableSchema,
        ConnectionString: this.DBConnection,
      })
      const tblDefinitionJson = await objKnex.GetTableDefinition()
      if (!isUndefined(tblDefinitionJson) && !isUndefined(tblDefinitionJson.TableDefinition)) {
        return tblDefinitionJson.TableDefinition
      }
    }
    return {}
  }

  /**
   * @function JsonSchemaToPostgresSchema
   * @noparams. Parameters are assumed from Class creation.
   * It requires the JsonSchema and a key in the Schema that
   * you want to use for finding postgres type.
   *
   * All Json Types should be defined in {@link DataTypeTransferEnum}
   *
   * Converts Json Schema to Postgre Column Defintion:
   * "SalesDirectorPublicKey": {
   *    "type": "string",
   *    "default": "",   // ignored
   *    "minLength": 36, // ignored
   *    "maxLength": 36  // if not present for stirng, then default is 512
   *  }
   * to
   *  "SalesDirectorPublicKey": {
   *    "Position": 1,
   *    "IsNullable": true, // always true
   *    "DataType": "varchar",
   *    "DataLength": 36,
   *    "precision": -1,
   *    "scale": -1,
   *    "datetimePrecision": -1
   *  }
   */
  async JsonSchemaToDBSchema(cleanColNames) {
    const dbSchema = {}
    try {
      // get json schema
      const colsAndTypesJson = this.JsonColumnsAndTypes()
      // convert to DB Schema
      if (colsAndTypesJson) {
        let idx = 0
        forEach(colsAndTypesJson, (colType, colName) => {
          const psqlTypeEnum = JsonPostgreTypeMappingEnum[colType.type]
          if (isUndefined(psqlTypeEnum)) {
            throw new Error(
              `No Postgres Type available for Column: ${colName} and Type: ${colType.type}`
            )
          }
          const cleanedName = cleanColNames ? GetCleanColumnName(colName) : colName
          dbSchema[cleanedName] = {
            Position: idx,
            IsNullable: true,
            DataType: psqlTypeEnum.postgres.dataType,
            DataLength: colType.maxLength || psqlTypeEnum.postgres.defaultLength || -1,
            precision: psqlTypeEnum.postgres.defaultPrecision || -1,
            scale: psqlTypeEnum.postgres.defaultScale || -1,
            datatimePrecision: -1,
          }
          idx += 1
        })
      }
    } catch (err) {
      throw new Error(`Error coverting Json to Psql Schema. ${err.message}`)
    }
    return dbSchema
  }

  async FindSchemaDiff(cleanColNames) {
    let jDiff
    // convert to DB Schema
    const sourceSchema = await this.JsonSchemaToDBSchema(cleanColNames)
    // get table schema
    const tblSchema = await this.TableSchemaToJson()
    if (isEmpty(tblSchema)) {
      // new table schema
      jDiff = {
        NewTable: {},
      }
      jDiff.NewTable = sourceSchema
      // DATA-760, Solution 2:
      if (
        (Object.keys(sourceSchema).length === 0 && this.HadNestedProperties) ||
        Object.keys(sourceSchema).length > 0
      ) {
        jDiff.CreateNewTable = true
      } else {
        throw new Error(
          `FinScheamDiff, Issue in diff for New Table. SourceSchema Length: ${
            Object.keys(sourceSchema).length
          }, JsonSchema Had Nested Props: ${this.HadNestedProperties}`
        )
      }
    } else {
      // compare and find diff
      jDiff = this.GetJsonDiff(tblSchema, sourceSchema)
    }
    return jDiff
  }

  /**
   *
   * @param {object} sqlTableSchema
   * @param {object} dynamoJsonSchema
   * targetSchema/sourceSchema format:
   * {
   *  "ColumnName" : {
   *    "Position": 1,      // position of column
   *    "IsNullable": true,
   *    "DataType": "int",  // could be int/number/string/other postgres data types, No Object/Array
   *    "DataLength" : 10,      // applicable only for string/similar types
   *    "precision": 10,    // applicable only for numeric/decimal types
   *    "scale": 2          // applicable only for numeric/decimal types
   *    "datetimePrecision": -1 // mostly -1 because we dont know the time precision
   *  }
   * }
   * Schema should not be in Json Schema format
   * Schema should not contain objects/arrays other than specified above
   * @returns
   * {
      AddedColumns: [
        {
          "ColumnName": {
            db_type: 'varchar(10)',
          },
          "ColumnName2": {
            db_type: 'numeric(10, 2)',
          },
          "ColumnName3": {
            db_type: 'int',
          },
        },
      ],
      DeletedColumns: [
        "ColumnName1", "ColumnName2"
      ],
      AlteredColumns: [
        {
          "ColumnName": {
            db_type: 'real',
          },
        },
      ],
    }
   */
  GetJsonDiff(sqlTableSchema, dynamoJsonSchema) {
    let output = {
      AddedColumns: {},
      DeletedColumns: {},
      AlteredColumns: {},
    }

    if (sqlTableSchema && dynamoJsonSchema) {
      // first find deleted columns
      forEach(sqlTableSchema, (colDef, targetColName) => {
        // const targetColName = Object.keys(colDef)[0]
        if (isUndefined(dynamoJsonSchema[targetColName])) {
          output.DeletedColumns[targetColName] = {}
          Object.assign(output.DeletedColumns[targetColName], colDef)
        }
      })
      // compare, position of column does not matter
      forEach(dynamoJsonSchema, (dynamoCol, srcFullColName) => {
        // const srcColName = Object.keys(dynamoCol)[0]
        // column exists
        const srcColName = srcFullColName.substr(0, 63)
        const targetCol = sqlTableSchema[srcColName]
        if (!isUndefined(targetCol)) {
          // Get updated type
          const newColType = GetNewType(targetCol, dynamoCol)
          if (!isEmpty(newColType)) {
            output.AlteredColumns[srcColName] = {}
            Object.assign(output.AlteredColumns[srcColName], newColType)
          }
        } else {
          // add column
          // const newColType = {}
          output.AddedColumns[srcColName] = {}
          Object.assign(output.AddedColumns[srcColName], dynamoCol)
          // newColType[srcColName] = dynamoCol
          // output.AddedColumns.push(newColType)
        }
      })
    }

    return output
  }

  /**
   * This function will check if col list 1 and 2 have
   * any matching columns by column name. if so it will throw an error
   * @param {*} colList1
   * @param {*} colList2
   */
  CheckForDuplicateCols(colList1, colList2) {
    if (colList1 && colList2 && isObject(colList1) && isObject(colList2)) {
      const listToLoop = size(colList1) < size(colList2) ? colList1 : colList2
      const listToCheck = size(colList1) < size(colList2) ? colList2 : colList1
      forEach(listToLoop, (column, colName) => {
        // check if column exists in the other list
        if (listToCheck[colName]) {
          // exists so throw an error
          throw new Error(
            `Column: ${colName} exists twice. Entry in List 1: ${JSON.stringify(
              column
            )}, Entry in List 2: ${JSON.stringify(
              listToCheck[colName]
            )}Check parameters to Create Table.`
          )
        }
      })
    }
  }

  async GenerateSQLFromJsonDiff(
    jsonDiff,
    defaultColsForNewTable = {},
    RemoveNonAlphaNumericCharsInColumnNames = true
  ) {
    let dbScript = ''
    try {
      if (jsonDiff) {
        const objtbl = new KnexTable({ TableName: this.TableName, TableSchema: this.TableSchema })
        // Fixing DATA-760, Solution 2: Some time New table doesn't have any columns
        // if the original objects didn't have any simple properties.
        //if (!isUndefined(jsonDiff.NewTable) && size(jsonDiff.NewTable) > 0) {
        if (!isUndefined(jsonDiff.NewTable) && jsonDiff.CreateNewTable) {
          // if default cols and new table cols have conflicting columns throw an error
          this.CheckForDuplicateCols(defaultColsForNewTable, jsonDiff.NewTable)
          // create new table with all columns
          Object.assign(defaultColsForNewTable, jsonDiff.NewTable)
          dbScript = await objtbl.getCreateTableSQL(
            defaultColsForNewTable,
            RemoveNonAlphaNumericCharsInColumnNames
          )
        } else {
          // alter table - ADD columns
          if (!isUndefined(jsonDiff.AddedColumns) && size(jsonDiff.AddedColumns) > 0) {
            dbScript = await objtbl.getAlterTableSQL(
              jsonDiff.AddedColumns,
              true,
              RemoveNonAlphaNumericCharsInColumnNames
            )
          }
          // alter table - modify columns
          if (!isUndefined(jsonDiff.AlteredColumns) && size(jsonDiff.AlteredColumns) > 0) {
            dbScript =
              dbScript +
              (await objtbl.getAlterTableSQL(
                jsonDiff.AlteredColumns,
                false,
                RemoveNonAlphaNumericCharsInColumnNames
              ))
          }
        }
      }
    } catch (err) {
      console.log('error', `Error creating script for Table: ${this.TableName}, ${err.message}`)
      throw new Error(`Error creating script for Table: ${this.TableName}, ${err.message}`)
    }
    // create alter script
    // console.log('info', dbScript)
    return dbScript
  }

  /**
   * @function SQLScript
   * @param {object} opts - These are options:
   *  AddTrackingCols : true/false
   *  AdditionalColumns : object
   *  If AddTrackingCols is true, provide those columns should be in AdditionalColumns
   *  and the object should in following format:
   *    "AdditionalColumns":
   *    {
   *    "ColumnName" : {
   *      "IsNullable": false,   -- not required, but if provided can be false/true
   *      "DataType": "integer", -- This is the only required property, it should be one of TYPES IN {@link DataTypeTransferEnum}
   *      "DataLength": -1,      -- Can be a number, if -1/0/undefined it is ignored.But, if DataType is string it is 256 by default
   *      "precision": 22,       -- Can be a valid number if -1/0/undefined it is ignored.But, if DataType is decimal/numeric it is 22 by default
   *      "scale": 8,            -- Can be a valid number if -1/0/undefined it is ignored.But, if DataType is decimal/numeric it is 8 by default
   *      "datetimePrecision": -1 -- Only applicable for timestamp or timestamptz
   *    }
   * This function generates a SQL script based on
   * differences between the Json schema and Table.
   *
   * If Json schema is missing a column that is in Table
   * then it doesn't delete that column.
   *
   * Only columns are added or altered.
   */
  async SQLScript(opts = {}) {
    let script
    try {
      this.ValidParameters()
      const jDiff = await this.FindSchemaDiff(opts.RemoveNonAlphaNumericCharsInColumnNames)
      // generate script
      const addCols = this.getTrackingCols(opts)
      script = await this.GenerateSQLFromJsonDiff(
        jDiff,
        addCols,
        opts.RemoveNonAlphaNumericCharsInColumnNames
      )
    } catch (err) {
      throw new Error(`Error in finding SQL Diff. ${err.message}`)
    }
    return script
  }

  getTrackingCols(opts = {}) {
    if (
      !isEmpty(opts) &&
      IsValidBoolean(opts.AddTrackingCols) &&
      !isEmpty(opts.AdditionalColumns) &&
      size(opts.AdditionalColumns) > 0
    ) {
      forEach(opts.AdditionalColumns, (col) => {
        if (!IsValidTypeObject(col)) {
          throw new Error(
            `opts.AddTrackingCols is true but opts.AdditionalColumns defintion is invalid for ${col}`
          )
        }
      })
      return opts.AdditionalColumns
    }
  }

  ValidParameters() {
    if (!IsValidString(this.TableName)) {
      new Error(`Invalid Param. Table Name is required. Provided: ${this.TableName}`)
    }
    if (!IsValidString(this.DBConnection)) {
      new Error(`Invalid Param. DBConnection is required. Provided: ${this.DBConnection}`)
    }
    if (isEmpty(this.JsonSchema)) {
      new Error(`Invalid Param. JsonSchema is required. Provided: ${this.JsonSchema}`)
    }
  }
}
