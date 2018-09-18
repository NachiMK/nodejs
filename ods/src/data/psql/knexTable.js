import { knexByConnectionString } from './index'
import { UploadS3FileToDB } from '../psql/bulkload/index'
import { IsValidString, CleanUpString } from '../../utils/string-utils'

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

  ValidateParams() {
    if (!IsValidString(this.DBConnection)) {
      throw new Error('Invalid Param. DBConnection is required.')
    }
    if (!IsValidString(this.TableName)) {
      throw new Error('Invalid Param. TableName is required')
    }
  }

  async DropTableIfExists() {
    let knex
    let blnDropped = false
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
    return blnExists
  }

  async UploadDataFromS3(s3FilePath) {
    const uploadResp = await UploadS3FileToDB({
      TableName: this.TableNameWithSchema,
      S3FilePath: s3FilePath,
      ConnectionString: this.DBConnection,
    })
    return uploadResp.CountAfterUpload
  }
}
