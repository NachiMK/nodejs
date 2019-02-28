import _ from 'lodash'
import moment from 'moment'
import { JsonSchemaToDBSchema } from './index'
import { GetCleanColumnName } from '../../data/psql/DataTypeTransform'

describe('JsonSchemaToDBSchema - Unit Tests', () => {
  it.skip('JsonSchemaToDBSchema should return DB Schema', async () => {
    const event = require('./event.json')
    const obj = new JsonSchemaToDBSchema(event)
    try {
      const resp = await obj.getDBScriptFromS3Schema()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      console.log(err.message)
    }
  })
  it.skip('JsonSchemaToDBSchema should save DB Schema', async () => {
    const event = require('./event.json')
    const obj = new JsonSchemaToDBSchema(event)
    try {
      const resp = await obj.saveDBSchema()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      console.log(err.message)
    }
  })
  it.only('knexTable - CreateTable Script', async () => {
    const tableSchema = 'raw'
    const tableName = `Employee_${moment().format('YYYYMMDD_HHmmssSSS')}`
    const jsonEmployee = {
      EmployeeId: { type: 'string', maxLength: 10 },
      FullName: { type: 'string', maxLength: 40 },
      Salary: { type: 'string', maxLength: 20 },
      ' My Employer': { type: 'string', maxLength: 20 },
      'My Address ': { type: 'string', maxLength: 20 },
      'MyAssets!': { type: 'string', maxLength: 20 },
      'My-cars': { type: 'string', maxLength: 20 },
    }
    const expectedSql = `create table "${tableSchema}"."${tableName}" 
      ("${jsonEmployee['EmployeeId']}" varchar(10) 
      , "${jsonEmployee['FullName']}" varchar(40) 
      , "${jsonEmployee['Salary']}" varchar(40) 
      , "${jsonEmployee[' My Employer']}" varchar(20) 
      , "${jsonEmployee['My Address ']}" varchar(20) 
      , "${jsonEmployee['MyAssets!']}" varchar(20) 
      , "${jsonEmployee['My-cars']}" varchar(20) 
      `
    const objJtoD = new JsonSchemaToDBSchema({
      TableNamePrefix: tableName,
      BatchId: 100,
      LogLevel: 'warn',
    })
    expect(objJtoD).toBeDefined()
    const dbScript = await objJtoD.getCreateTableSQL(tableSchema, tableName, jsonEmployee, true)
    console.log(`dbcript: ${dbScript}`)
    expect(dbScript).toBeDefined()
    _.forEach(jsonEmployee, (col, colName) => {
      const colRegEx = new RegExp(GetCleanColumnName(colName), 'gm')
      console.log(
        `colName: "${colName}", Cleaned: "${GetCleanColumnName(colName)}" Matched? ${dbScript.match(
          colRegEx
        )}`
      )
      expect(_.isArray(dbScript.match(colRegEx))).toEqual(true)
      expect(dbScript.match(colRegEx)[0]).toEqual(GetCleanColumnName(colName))
    })
  })
})
