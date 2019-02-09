import forEach from 'lodash/forEach'
import isUndefined from 'lodash/isUndefined'
import { knexByConnectionString, executeScalar } from '..'
import { UploadS3FileToDB } from '../bulkload'
import { IsValidString, CleanUpString } from '../../../utils/string-utils'
import { knexNoDB } from '..'
import { DataTypeTransferEnum, IsValidTypeObject } from '../DataTypeTransform'

export class KnexTable {
  constructor(params) {
    this._dbConn = params.ConnectionString || ''
    this._tableName = params.TableName || ''
    this._tableSchema = CleanUpString(params.TableSchema, 'public')
  }
  get DBConnection() {
    return this._dbConn
  }
  get TableName() {
    return this._tableName
  }
  get TableSchema() {
    return this._tableSchema
  }
  get TableNameWithSchema() {
    return `${this.TableSchema}.${this.TableName}`
  }

  ValidateParams(checkConnection = false) {
    if (checkConnection && !IsValidString(this.DBConnection)) {
      throw new Error('Invalid Param. DBConnection is required.')
    }
    if (!IsValidString(this.TableName)) {
      throw new Error('Invalid Param. TableName is required')
    }
    if (!IsValidString(this.TableSchema)) {
      throw new Error('Invalid Param. TableSchema is required.')
    }
  }

  NewTableValidation() {
    if (!IsValidString(this.TableName)) {
      throw new Error('Invalid Param. TableName is required')
    }
    if (this.TableName.length > 63 || this.TableName.length < 1) {
      throw new Error(
        `Invalid Param. TableName:${this.TableName}, Len: ${
          this.TableName.length
        } should be between 1 than 63`
      )
    }
    const tblRegEx = /[^a-z\d_]+/gi
    if (tblRegEx.test(this.TableName)) {
      throw new Error(
        `Invalid Param. TableName:${this.TableName} should contain only Alpha Numeric chars`
      )
    }
    const tblRegExStart = /^[a-z]+/gi
    if (!tblRegExStart.test(this.TableName)) {
      throw new Error(`Invalid Param. TableName:${this.TableName} should start with Alphabhet`)
    }
  }

  async DropTableIfExists() {
    let knex
    let blnDropped = false
    this.ValidateParams(true)
    try {
      // get knex type
      knex = knexByConnectionString(this.DBConnection)
      // create table
      blnDropped = await knex.schema.withSchema(this.TableSchema).dropTableIfExists(this.TableName)
    } catch (err) {
      throw err
    } finally {
      if (knex) {
        knex.destroy()
      }
    }
    return blnDropped
  }

  async TableExists() {
    let blnExists = false
    let knex
    try {
      // get knex type
      knex = knexByConnectionString(this.DBConnection)
      // create table
      blnExists = await knex.schema.withSchema(this.TableSchema).hasTable(this.TableName)
    } catch (err) {
      throw err
    } finally {
      if (knex) {
        knex.destroy()
      }
    }
    return blnExists
  }

  async RowCount() {
    let intRowCount = -1
    this.ValidateParams(true)
    let knex
    try {
      // get knex type
      knex = knexByConnectionString(this.DBConnection)
      // create table
      const cnt = await knex(this.TableNameWithSchema).count('*')
      if (cnt) {
        intRowCount = isNaN(Number(cnt)) ? 0 : Number(cnt)
      } else {
        intRowCount = 0
      }
    } catch (err) {
      throw err
    } finally {
      if (knex) {
        knex.destroy()
      }
    }
    return intRowCount
  }

  async UploadDataFromS3(s3FilePath) {
    const uploadResp = await UploadS3FileToDB({
      TableName: `"${this.TableSchema}"."${this.TableName}"`.replace('""', '"'),
      S3FilePath: s3FilePath,
      ConnectionString: this.DBConnection,
    })
    return uploadResp.CountAfterUpload
  }

  async GetTableDefinition() {
    const retSingleValue = {}
    let knex
    this.ValidateParams(true)
    try {
      // get knex type
      knex = knexByConnectionString(this.DBConnection)
      const Query = getTableDefinitionQuery(this.TableName, this.TableSchema)
      const resExeScalar = await knex.raw(Query)
      if (resExeScalar) {
        if (resExeScalar.rows && resExeScalar.rows.length > 0) {
          // @ts-ignore
          const value = Object.values(resExeScalar.rows[0])[0]
          retSingleValue.TableDefinition = value
          retSingleValue.completed = true
        }
      }
    } catch (err) {
      throw new Error(`Error in getting ${this.TableName}: definition, Error: ${err.message}`)
    } finally {
      if (knex) {
        knex.destroy()
      }
    }
    return retSingleValue
  }

  getPostgresColType(column) {
    let retType // = 'VARCHAR(256)'
    if (column) {
      const datatypeEnum = DataTypeTransferEnum[column.DataType]
      const textEnum = DataTypeTransferEnum['text']
      const useText = !isUndefined(datatypeEnum.UseTextForLongerStrings)
        ? datatypeEnum.UseTextForLongerStrings
        : false
      if (datatypeEnum) {
        // check if provided column has any length information
        if (!isUndefined(column.DataLength) && column.DataLength > 0) {
          retType =
            useText && column.DataLength > 512
              ? textEnum.postgresType
              : `${datatypeEnum.postgresType}(${column.DataLength})`
        } else if (!isUndefined(column.precision) && column.precision > 0) {
          // precision
          const scale = column.scale || 0
          retType = `${datatypeEnum.postgresType}(${column.precision}, ${scale})`
        } else if (!isUndefined(column.PrimaryKey) && column.PrimaryKey) {
          retType = `${datatypeEnum.postgresType} PRIMARY KEY NOT NULL`
        } else {
          retType = datatypeEnum.postgresType
        }
      }
    }
    return retType
  }

  /**
   *
   * @param {object} columnSchema
   * columnSchema is a list of objects, where object key is column
   * name and the object has at least one key which is "type"
   * "type" should be one of allowed postgres type
   * Sample object:
   * {
   *  "RowId" : {
   *    "Position": 1,  -- Position is required if you want the table order to be what you define
   *    "IsNullable": false, -- not required, but if provided can be false/true
   *    "DataType": "integer", -- This is the only required property, it should be one of TYPES IN {@link DataTypeTransferEnum}
   *    "DataLength": -1,      -- Can be a number, if -1/0/undefined it is ignored.But, if DataType is string it is 256 by default
   *    "precision": 32,       -- Can be a valid number if -1/0/undefined it is ignored.But, if DataType is decimal/numeric it is 22 by default
   *    "scale": 0,            -- Can be a valid number if -1/0/undefined it is ignored.But, if DataType is decimal/numeric it is 8 by default
   *    "datetimePrecision": -1 -- Only applicable for timestamp or timestamptz
   *  }
   * }
   *
   */
  async getCreateTableSQL(columnSchema) {
    let knex
    let dbScript
    const tableSchema = this.TableSchema
    const tableName = this.TableName
    this.ValidateParams(false)
    this.NewTableValidation()
    // loop through columns
    const colNames = Object.keys(columnSchema)
    if (colNames && colNames.length > 0) {
      try {
        // get knex type
        knex = knexNoDB()
        // create table
        dbScript = await knex.schema
          .withSchema(tableSchema)
          .createTable(tableName, (table) => {
            forEach(columnSchema, (column, colName) => {
              try {
                // is data type defined
                if (IsValidTypeObject(column) && DataTypeTransferEnum[column.DataType]) {
                  // get data type, with length
                  const dtType = this.getPostgresColType(column)
                  // add column
                  table.specificType(colName, dtType)
                } else {
                  throw new Error(
                    `Invalid Datatype: ${column.DataType} provided for Table:${tableName}`
                  )
                }
              } catch (err) {
                // on error quit
                const e = new Error(
                  `Error in adding column: ${colName} to Table: ${tableName}, error: ${err.message}`
                )
                console.log(e.message)
                throw e
              }
            })
          })
          // @ts-ignore
          .toSQL()
      } catch (err) {
        throw new Error(`Error in adding cols to Table: ${tableName}, error: ${err.message}`)
      } finally {
        if (knex) {
          knex.destroy()
        }
      }
      // throw error in case of invalid script object
      if (!(dbScript && dbScript.length && dbScript.length > 0 && dbScript[0].sql)) {
        throw new Error(
          `Create Table script failed with unknown error. sql attribute missing. dbScript: ${dbScript}`
        )
      }
      return dbScript[0].sql
    } else {
      throw new Error('columnSchema is empty. Cannot get Create Table SQL Statement')
    }
  }

  async getAlterTableSQL(columnSchema, addColumns = false) {
    let knex
    let dbScript
    const tableSchema = this.TableSchema
    const tableName = this.TableName
    this.ValidateParams(false)
    // loop through columns
    const colNames = Object.keys(columnSchema)
    if (colNames && colNames.length > 0) {
      try {
        // get knex type
        knex = knexNoDB()
        // create table
        dbScript = await knex.schema
          .withSchema(tableSchema)
          .alterTable(tableName, (table) => {
            forEach(columnSchema, (column, colName) => {
              try {
                // is data type defined
                if (IsValidTypeObject(column) && DataTypeTransferEnum[column.DataType]) {
                  // get data type, with length
                  const dtType = this.getPostgresColType(column)
                  // add column
                  if (addColumns) {
                    table.specificType(colName, dtType)
                  } else {
                    table.specificType(colName, dtType).alter()
                  }
                } else {
                  throw new Error(
                    `Invalid Datatype: ${column.DataType} provided for Table:${tableName}`
                  )
                }
              } catch (err) {
                // on error quit
                const e = new Error(
                  `Error in adding column: ${colName} to Table: ${tableName}, error: ${err.message}`
                )
                console.log(e.message)
                throw e
              }
            })
          })
          // @ts-ignore
          .toSQL()
      } catch (err) {
        throw new Error(`Error in adding cols to Table: ${tableName}, error: ${err.message}`)
      } finally {
        if (knex) {
          knex.destroy()
        }
      }
      // throw error in case of invalid script object
      if (!(dbScript && dbScript.length && dbScript.length > 0 && dbScript[0].sql)) {
        throw new Error(
          `Create Table script failed with unknown error. sql attribute missing. dbScript: ${dbScript}`
        )
      }
      // dbScript is an array of SQL statements, combine them all
      return (
        dbScript
          .map((item) => item.sql)
          .join(';\n')
          .replace(',;', ';') + ';\n'
      )
    } else {
      throw new Error('Invalid Param. columnSchema is empty. Cannot get Alter Table SQL Statement')
    }
  }

  async CopyDataFromPreStage(params = {}) {
    let rowCount
    const { PreStageTableName, DataPipeLineTaskQueueId } = params
    if (!isUndefined(PreStageTableName) && !isUndefined(DataPipeLineTaskQueueId)) {
      try {
        const qParams = {
          Query: getCopyDataQuery(
            PreStageTableName,
            this.TableName,
            this.TableSchema,
            DataPipeLineTaskQueueId
          ),
          ConnectionString: this.DBConnection,
          BatcId: DataPipeLineTaskQueueId,
        }
        const retRS = await executeScalar(qParams)
        if (retRS && retRS.completed) {
          rowCount = isNaN(parseInt(retRS.scalarValue)) ? -1 : parseInt(retRS.scalarValue)
        } else {
          throw new Error(
            `Copy Data for BatchId :${DataPipeLineTaskQueueId} completed but did not load data. Response:${retRS}`
          )
        }
      } catch (err) {
        const e = new Error(
          `Error copying data to Table: ${this.TableName} from PreStage: ${PreStageTableName}, ${
            err.message
          }`
        )
        throw e
      }
    } else {
      throw new Error(
        `Invalid Parameter. Either ${PreStageTableName} is undefined or ${DataPipeLineTaskQueueId} is empty.`
      )
    }
    return rowCount
  }
}

function getTableDefinitionQuery(tableName, tableschema = 'public') {
  // return columns as objects
  // to return as array of objects use: SELECT json_agg(json_build_object(
  return `
  SELECT  json_object_agg
        (
            column_name, 
            (
                SELECT row_to_json(t)
                FROM   
                (
                    SELECT 
                         ordinal_position as "Position"
                        ,CASE WHEN is_nullable = 'YES' THEN true ELSE false END as "IsNullable"
                        ,lower(data_type) as "DataType"
                        ,COALESCE(character_maximum_length, -1) as "DataLength"
                        ,CASE WHEN lower(data_type) IN ('smallint', 'int', 'integer'
                                                      , 'bigint', 'smallserial'
                                                      , 'serial', 'bigserial')
                              THEN -1 
                              ELSE COALESCE(numeric_precision, -1) 
                        END as "precision"
                        ,COALESCE(numeric_scale, -1) as "scale"
                        ,COALESCE(datetime_precision, -1)  as "datetimePrecision"
                    FROM    INFORMATION_SCHEMA.COLUMNS I2
                    WHERE   I2.column_name = I1.column_name
                    AND     I2.table_name = I1.table_name
                    AND     I2.table_schema = I1.table_schema
                    AND     I2.table_catalog = I1.table_catalog
                ) t
            )
        ) as "TableDefinition"
  FROM    INFORMATION_SCHEMA.COLUMNS I1
  WHERE   I1.table_name = '${tableName}'
  AND     I1.table_schema = '${tableschema}'`
}

function getCopyDataQuery(preStageTableName, tableName, tableSchema, dataPipeLineTaskQueueId) {
  const [preStgSchema, preStgTable] = preStageTableName.split('.')
  return `SELECT * FROM public."udf_CopyPreStageToStage"('${tableSchema}'
  , '${tableName}'
  , '${preStgSchema}'
  , '${preStgTable}'
  , '${dataPipeLineTaskQueueId}')`
}
