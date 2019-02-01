import { getAndSetVarsFromEnvFile } from '../../../env'
import { PostgresRawToStage } from './psql-raw-to-stage'

// npm run test -t src/modules/psql-raw-to-stage/generate.test.js
// npm run build && clear && STAGE=int npm run test -t src/modules/psql-raw-to-stage/generate.test.js

describe('Unit Tests PostgresRawToStage', () => {
  getAndSetVarsFromEnvFile(false)
  it('should Create empty object', () => {
    const obj = new PostgresRawToStage()
    expect(obj).toBeDefined()
    expect(obj.ToString()).toBeDefined()
    // has defaults
    expect(obj.DataTypeKey).toEqual('db_type')
  })
  it('should Create object with params', () => {
    const tblName = 'testtable-1'
    const obj = new PostgresRawToStage({
      StageTableName: tblName,
    })
    expect(obj).toBeDefined()
    // has parameters we sent
    expect(obj.StageTableName).toEqual(tblName)
  })
  it('should Create object but not valid', () => {
    const tblName = 'testtable-1'
    const obj = new PostgresRawToStage({
      StageTableName: tblName,
    })
    expect(obj).toBeDefined()
    // has invalid params
    expect(() => {
      obj.IsValidParam()
    }).toThrowError('Invalid Param')
  })
  it('should Create object and it is valid', () => {
    const event = require('./raw-to-stage-event.json')
    const obj = new PostgresRawToStage(event)
    expect(obj).toBeDefined()
    // has invalid params
    expect(obj.IsValidParam()).toEqual(true)
  })
  it('should Create object and stage data', async () => {
    const event = require('./raw-to-stage-event.json')
    const obj = new PostgresRawToStage(event)
    // has invalid params
    expect(obj.IsValidParam()).toEqual(true)
    expect.assertions(1)
    const loadResp = await obj.LoadData()
    expect(loadResp).toBeDefined()
    expect(loadResp.status.message).toEqual('success')
    expect(loadResp.Attributes.DataCopied).toEqual(true)
    if (loadResp.Attributes.DataCopied) {
      expect(loadResp.Attributes.RowCount).toBeGreaterThan(0)
    }
  })
})
