import jsonSchemaSaver from '.'

describe('ods-schema-builder - Integration Tests', () => {
  it.only('ods-schema-builder should create schema file', async () => {
    const resp = await jsonSchemaSaver({
      Datafile: 's3://dev-ods-data/dynamodb/clients/49/49-clients-Data-20180823_183955032.json',
      Output: 's3://dev-ods-data/unit-test/clients/test-clients-Schema-',
      Overwrite: 'yes',
      S3RAWJsonSchemaFile: 's3://dev-ods-data/dynamotableschema/clients-20180906_132212919.json',
    })
    expect(resp.status.message).toBe('success')
    expect(resp.file).toBeDefined()
    console.log(JSON.stringify(resp, null, 2))
  })
})
