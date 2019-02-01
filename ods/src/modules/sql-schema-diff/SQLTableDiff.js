import isUndefined from 'lodash/isUndefined'
import isEmpty from 'lodash/isEmpty'
import omit from 'lodash/omit'
import { IsValidString } from '../../utils/string-utils'
import { KnexTable } from '../../data/psql/table/knexTable'
import { SchemaDiff } from '../json-sql-schema-diff'

export class SQLTableDiff {
  constructor(params = {}) {
    this._sourceTable = params.SourceTable || ''
    this._sourceTableSchema = params.SourceTableSchema || 'public'
    this._targetTable = params.TargetTable || ''
    this._targetTableSchema = params.TargetTableSchema || 'public'
    this._sourceDBConn = params.SourceDBConnection || ''
    this._targetDBConn = params.TargetDBConnection || ''
    this._LogLevel = params.LogLevel || 'warn'
  }
  get LogLevel() {
    return this._LogLevel
  }
  get SourceTable() {
    return this._sourceTable
  }
  get SourceTableSchema() {
    return this._sourceTableSchema
  }
  get TargetTable() {
    return this._targetTable
  }
  get TargetTableSchema() {
    return this._targetTableSchema
  }
  get SourceDBConnection() {
    return this._sourceDBConn
  }
  get TargetDBConnection() {
    return this._targetDBConn
  }

  async ValidateParam() {
    if (!IsValidString(this.SourceTable)) {
      throw new Error(`InValidParam. SourceTable is required.`)
    }
    if (!IsValidString(this.TargetTable)) {
      throw new Error(`InValidParam. TargetTable is required.`)
    }
    if (!IsValidString(this.SourceDBConnection)) {
      throw new Error(`InValidParam. SourceDBConnection is required.`)
    }
    if (!IsValidString(this.TargetDBConnection)) {
      throw new Error(`InValidParam. TargetDBConnection is required.`)
    }
    const blnSourceExists = await this.TableExists(
      this.SourceTable,
      this.SourceTableSchema,
      this.SourceDBConnection
    )
    if (!blnSourceExists) {
      throw new Error(`InValidParam. SourceTable does not exists in DB.`)
    }
  }

  async TableExists(tbl, schema, cs) {
    let blnRet = false
    const objKnex = new KnexTable({
      ConnectionString: cs,
      TableName: tbl,
      TableSchema: schema,
    })
    blnRet = await objKnex.TableExists()
    return blnRet
  }

  async GetSQLDiffScript(defaultColumns = {}, SourceColsToIgnore = {}) {
    try {
      await this.ValidateParam()
      const defOutput = await this.GetTableSchema()
      if (!isEmpty(defOutput) && !isEmpty(defOutput.SourceDefinition)) {
        // remove columns we want to ignore from source
        defOutput.SourceDefinition = omit(
          defOutput.SourceDefinition,
          Object.keys(SourceColsToIgnore)
        )
        let jDiff = {}
        const objSchDiff = new SchemaDiff({
          JsonSchema: {},
          TableName: this.TargetTable,
          TableSchema: this.TargetTableSchema,
          DataTypeKey: 'db_type',
          DBConnection: this.TargetDBConnection,
        })
        if (isEmpty(defOutput.TargetDefintion)) {
          jDiff.NewTable = {}
          jDiff.CreateNewTable = true
          Object.assign(jDiff.NewTable, defOutput.SourceDefinition)
        } else {
          jDiff = await objSchDiff.GetJsonDiff(
            defOutput.TargetDefintion,
            defOutput.SourceDefinition
          )
        }
        // generate script
        const script = await objSchDiff.GenerateSQLFromJsonDiff(jDiff, defaultColumns)
        return script
      }
    } catch (err) {
      throw new Error(`Error generating sql diff script: ${err.message}`)
    }
  }

  async GetTableSchema() {
    const output = {
      SourceDefinition: {},
      TargetDefintion: {},
    }
    // get table schema
    const objKnex = new KnexTable({
      TableName: this.SourceTable,
      TableSchema: this.SourceTableSchema,
      ConnectionString: this.SourceDBConnection,
    })
    const tblDefinitionJson = await objKnex.GetTableDefinition()
    if (!isUndefined(tblDefinitionJson) && !isUndefined(tblDefinitionJson.TableDefinition)) {
      output.SourceDefinition = tblDefinitionJson.TableDefinition
      const blnTargetExists = await this.TableExists(
        this.TargetTable,
        this.TargetTableSchema,
        this.TargetDBConnection
      )
      if (blnTargetExists) {
        // find difference
        const objTarget = new KnexTable({
          TableName: this.TargetTable,
          TableSchema: this.TargetTableSchema,
          ConnectionString: this.TargetDBConnection,
        })
        const targetJsonDef = await objTarget.GetTableDefinition()
        if (!isUndefined(tblDefinitionJson) && !isUndefined(tblDefinitionJson.TableDefinition)) {
          output.TargetDefintion = targetJsonDef.TableDefinition
          // compare and find difference
        } else {
          throw new Error(`${this.TargetTable} schema definition is not found.`)
        }
      }
    } else {
      throw new Error(`${this.SourceTable} schema definition is not found.`)
    }
    return output
  }
}
