import { deleteByPath, deleteInFileByPath } from './delete-json-objects-by-keys'

describe('delete-json-objects-by-keys - Unit Tests', () => {
  const event = require('./event.json')
  const testByFile = event[0]
  const testByData = event[1]
  const testByArray = event[2]
  const testCmplx = event[3]
  it('Delete Single Key', () => {
    const delResp = deleteByPath({
      JsonData: testByData.JsonData,
      CommaSeparatedPaths: 'EnrollmentDate',
      LogLevel: testByData.LogLevel,
    })
    console.log(`Delete Single Key Resp: ${JSON.stringify(delResp, null, 2)}`)
    expect(delResp).toBeDefined()
    expect(delResp.EnrollmentDate).toBeUndefined()
  })
  it('Delete Multiple Keys', () => {
    const delResp = deleteByPath({
      JsonData: testByData.JsonData,
      CommaSeparatedPaths: testByData.JsonKeysToDelete,
      LogLevel: testByData.LogLevel,
    })
    console.log(`Delete Multiple Keys Resp: ${JSON.stringify(delResp, null, 2)}`)
    expect(delResp).toBeDefined()
    expect(delResp.EnrollmentDate).toBeDefined()
    expect(delResp.CartBackup).toBeDefined()
    expect(delResp.CartBackup.Cart).toBeUndefined()
    expect(delResp.TestNode).toBeDefined()
    expect(delResp.TestNode.ChildNode).toBeUndefined()
    expect(delResp.Cart).toBeDefined()
    expect(delResp.Cart[0].Benefit).toBeDefined()
    expect(delResp.Cart[0].Benefit.CoveredPeople).toBeUndefined()
  })
  it('Delete Undefined Key', () => {
    const delResp = deleteByPath({
      JsonData: testByData.JsonData,
      CommaSeparatedPaths: 'KeyNotToBeFound',
      LogLevel: testByData.LogLevel,
    })
    console.log(`Delete Undefined Key Resp: ${JSON.stringify(delResp, null, 2)}`)
    expect(delResp).toBeDefined()
    expect(delResp.EnrollmentDate).toBeDefined()
    expect(delResp.KeyNotToBeFound).toBeUndefined()
  })
  it('Delete Keys in an Array', () => {
    const delResp = deleteByPath({
      JsonData: testByArray.JsonData,
      CommaSeparatedPaths: testByArray.JsonKeysToDelete,
      LogLevel: testByData.LogLevel,
    })
    console.log(`Delete Keys in Array Resp: ${JSON.stringify(delResp, null, 2)}`)
    expect(delResp).toBeDefined()
    expect(delResp[0].Person).toBeDefined()
    expect(delResp[0].Person.Assets).toBeDefined()
    expect(delResp[0].Person.Assets[0].Address).toBeDefined()
    expect(delResp[0].Person.Assets[0].Zip).toBeUndefined()
    expect(delResp[1].Person.Assets[0].Zip).toBeUndefined()
    expect(delResp[1].Person.Assets[0].ZipCode).toBeDefined()
  })
  it('Delete Complicated Keys', () => {
    const delResp = deleteByPath({
      JsonData: testCmplx.JsonData,
      CommaSeparatedPaths: testCmplx.JsonKeysToDelete,
      LogLevel: testCmplx.LogLevel,
    })
    console.log(`Delete Complicated Keys Resp: ${JSON.stringify(delResp, null, 2)}`)
    expect(delResp).toBeDefined()
    expect(delResp.Person).toBeDefined()
    expect(delResp.Person['Zip Code']).toBeUndefined()
    expect(delResp.Person['My Documents']).toBeDefined()
    const c = delResp.Person['My Documents']
    expect(c['File Type']).toBeUndefined()
  })
  it.only('Delete Keys for data in File', async () => {
    expect.assertions(9)
    const delResp = await deleteInFileByPath({
      S3FilePath: testByFile.S3FilePath,
      CommaSeparatedPaths: testByFile.JsonKeysToDelete,
      LogLevel: testByFile.LogLevel,
    })
    console.log(`Delete Keys for data in File Resp: ${JSON.stringify(delResp, null, 2)}`)
    expect(delResp[0]).toBeDefined()
    expect(delResp[0].EnrollmentDate).toBeDefined()
    expect(delResp[0].CartBackup).toBeDefined()
    expect(delResp[0].CartBackup.Cart).toBeUndefined()
    expect(delResp[0].TestNode).toBeDefined()
    expect(delResp[0].TestNode.ChildNode).toBeUndefined()
    expect(delResp[0].Cart).toBeDefined()
    expect(delResp[0].Cart[0].Benefit).toBeDefined()
    expect(delResp[0].Cart[0].Benefit.CoveredPeople).toBeUndefined()
  })
})
