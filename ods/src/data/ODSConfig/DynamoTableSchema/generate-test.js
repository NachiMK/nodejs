import moment from 'moment'
import { GetDynamoTablesToRefreshSchema, UpdateSchemaFile } from './index'

function testGetDynamoTablesToRefreshSchema() {
  // const params = {
  //   RefreshAll: true,
  //   RefreshTableList: 'clients,persons,locations',
  // };
  const params = {}
  GetDynamoTablesToRefreshSchema(params)
    .then((res) => console.log('results:', JSON.stringify(res, null, 2)))
    .catch((err) => console.log('error calling proc:', JSON.stringify(err, null, 2)))
}

testGetDynamoTablesToRefreshSchema()
testUpdateSchemaFile()

function testUpdateSchemaFile() {
  const id = -19
  const s3path = `s3://dev-ods-data/dynamotableschema/clients-${moment().format(
    'YYYYMMDD_HHmmssSSS'
  )}.json`
  UpdateSchemaFile(id, s3path)
    .then((res) => console.log('results:', JSON.stringify(res, null, 2)))
    .catch((err) => console.log('error calling proc:', JSON.stringify(err, null, 2)))
}

// npm run build && clear && odsloglevel=info STAGE=DEV log_dbname=ODSLog node lib/data/ODSConfig/DynamoTableSchema/generate-test.js
