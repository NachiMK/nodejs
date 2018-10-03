//@ts-check
import isEmpty from 'lodash/isEmpty'
import forEach from 'lodash/forEach'
import isUndefined from 'lodash/isUndefined'
import size from 'lodash/size'
import { ExtractMatchingKeyFromSchema } from '../json-extract-matching-keys/index'
import { KnexTable } from '../../data/psql/table/knexTable'
import { IsValidString } from '../../utils/string-utils'
import {
  GetNewType,
  DataTypeTransferEnum,
  JsonPostgreTypeMappingEnum,
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
        includeMaxLength: true,
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
  async JsonSchemaToDBSchema() {
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
          dbSchema[colName] = {
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

  async FindSchemaDiff() {
    let jDiff
    // convert to DB Schema
    const sourceSchema = await this.JsonSchemaToDBSchema()
    // get table schema
    const tblSchema = await this.TableSchemaToJson()
    if (isEmpty(tblSchema)) {
      // new table schema
      jDiff = {
        NewTable: {},
      }
      jDiff.NewTable = sourceSchema
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
      forEach(dynamoJsonSchema, (dynamoCol, srcColName) => {
        // const srcColName = Object.keys(dynamoCol)[0]
        // column exists
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

  async GenerateSQLFromJsonDiff(jsonDiff) {
    let dbScript
    try {
      if (jsonDiff) {
        const objtbl = new KnexTable({ TableName: this.TableName, TableSchema: this.TableSchema })
        if (!isUndefined(jsonDiff.NewTable) && size(jsonDiff.NewTable) > 0) {
          // create new table with all columns
          dbScript = await objtbl.getCreateTableSQL(jsonDiff.NewTable, true)
        } else if (
          (!isUndefined(jsonDiff.AddedColumns) && size(jsonDiff.AddedColumns) > 0) ||
          !isUndefined(jsonDiff.AlteredColumns && size(jsonDiff.AlteredColumns) > 0)
        ) {
          // alter table
          dbScript = await objtbl.getAlterTableSQL(jsonDiff.AddedColumns, true)
          dbScript = dbScript + (await objtbl.getAlterTableSQL(jsonDiff.AlteredColumns))
        }
      }
    } catch (err) {
      console.log('error', `Error creating script for Table: ${this.TableName}, ${err.message}`)
    }
    // create alter script
    console.log('info', dbScript)
    return dbScript
  }

  /**
   * @function SQLScript
   * This function generates a SQL script based on
   * differences between the Json schema and Table.
   *
   * If Json schema is missing a column that is in Table
   * then it doesn't delete that column.
   *
   * Only columns are added or altered.
   */
  async SQLScript() {
    let script
    try {
      this.ValidParameters()
      const jDiff = await this.FindSchemaDiff()
      // generate script
      script = await this.GenerateSQLFromJsonDiff(jDiff)
    } catch (err) {
      throw new Error(`Error in finding SQL Diff. ${err.message}`)
    }
    return script
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
