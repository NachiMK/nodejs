import _ from 'lodash'
import { getAndSetVarsFromEnvFile } from '../../env'
import { CreateSchema } from '../service/dbadmin/dynamo/schema/index.js'
import { exportDynamoTable } from '../modules/dynamo-table-to-s3/dynamo-table-s3'
import jsonSchemaSaver from '../modules/ods-schema-builder'
import { JsonDataNormalizer } from '../modules/json-data-normalizer/index'
import { JsonObjectArrayToS3CSV } from '../modules/json-object-arrays-to-s3-csv'
import { CsvToPostgres } from '../modules/csv-to-postgres/index'

async function TestModules() {
  let event = getEventFromParams()
  getAndSetVarsFromEnvFile(false)
  try {
    event.JsonSchemaFilePath = '' //await Step1_CreateSchema(event)
    event.DataFile = await Step2_GetDataFile(event)
    event.CombinedSchemaFile = await Step3_CreateSchemaFromData(event)
    event.S3FlatJsonFile = await Step4_NormalizeData(event)
    event.JsonToCSVResp = await Step5_JsonToCSV(event)
    event.CsvToPostgresResp = await Step6_CSVtoPostgres(event)
    return 'success'
  } catch (err) {
    console.error(`Error: ${err.message}`)
    throw new Error(`Error in testing modules: ${JSON.stringify(err, null, 2)}`)
  }
}

console.time('debugModules')
TestModules()
  .then((res) => {
    console.log(`res: ${JSON.stringify(res, null, 2)}`)
    console.timeEnd('debugModules')
  })
  .catch((err) => {
    console.error(`err: ${JSON.stringify(err)}`)
    console.timeEnd('debugModules')
  })

function getEventFromParams() {
  let event = require('./event.json')
  process.argv.forEach((val, index) => {
    console.log(`Node Command Line Parameters: ${index}: ${val}`)
  })

  if (process.argv && process.argv.length > 2 && process.argv[2] && process.argv[2].length > 0) {
    console.log(`Event File to process as per command line Args: ${process.argv[2]}`)
    event = require('./process.argv[2]')
  }
  if (!event) {
    console.error(`Invalid event file name was provided: ${event}`)
    throw new Error(`Invalid event file name was provided`)
  }
  console.log(`Params to be used: ${JSON.stringify(event, null, 2)}`)
  return event
}

async function Step1_CreateSchema(event) {
  const params = {
    DynamoTableSchemaId: 800,
    DataPipeLineTaskId: 107,
    DynamoTableName: event.DynamoTableName,
    S3JsonSchemaPath: event.RawSchema,
  }
  console.log(`CreateSchema Params: ${JSON.stringify(params, null, 2)}`)
  const resp = await CreateSchema(params)
  console.log(`CreateSchema Resp: ${JSON.stringify(resp, null, 2)}`)
  return resp.S3FilePath
}

async function Step2_GetDataFile(event) {
  let eventData = {
    DynamoTableName: event.DynamoTableName,
    S3OutputBucket: event.S3Bucket,
  }
  Object.assign(eventData, event.DynamoTableToS3Params)
  console.log(`Export Table Params: ${JSON.stringify(eventData, null, 2)}`)
  const resp = await exportDynamoTable(eventData)
  console.log('Get Data resp', JSON.stringify(resp, null, 2))
  return resp.SaveResponse[event.DynamoTableName].Files[0].S3File
}

async function Step3_CreateSchemaFromData(event) {
  const params = {
    Datafile: event.DataFile,
    Output: event.CombinedOutput,
    Overwrite: 'yes',
    S3RAWJsonSchemaFile: event.RawSchema,
  }
  console.log(`Save Combined Schema Params: ${JSON.stringify(params, null, 2)}`)
  const resp = await jsonSchemaSaver(params)
  console.log(`JSON Schema Save Response: ${JSON.stringify(resp, null, 2)}`)
  return resp.file
}

async function Step4_NormalizeData(event) {
  const params = {
    S3DataFile: event.DataFile,
    S3SchemaFile: event.CombinedSchemaFile,
    S3OutputBucket: event.S3Bucket,
    TableName: event.DynamoTableName,
    ...event.JsonDataNormalizerParams,
  }
  console.log(`Json Normalizer Params: ${JSON.stringify(params, null, 2)}`)
  const resp = await JsonDataNormalizer(params)
  console.log(`JSON Normalizer Response: ${JSON.stringify(resp, null, 2)}`)
  return resp.S3FlatJsonFile
}

async function Step5_JsonToCSV(event) {
  const params = {
    S3DataFilePath: event.S3FlatJsonFile,
    S3OutputBucket: event.S3Bucket,
    ...event.FlatToCSV,
  }
  console.log(`Flat Json to CSV Params: ${JSON.stringify(params, null, 2)}`)
  const objJsonToCSV = new JsonObjectArrayToS3CSV(params)
  await objJsonToCSV.CreateFiles()
  console.log(
    `Flat Json to CSV Response: ${JSON.stringify(objJsonToCSV.ProcessedKeyAndFiles(), null, 2)}`
  )
  return objJsonToCSV.ProcessedKeyAndFiles()
}

async function Step6_CSVtoPostgres(event) {
  const tblName = event.DynamoTableName.replace(/(\bint|\bdev|\bprod)+-+/gi, '')
    .replace(/\bods+-+/gi, '')
    .replace(/-/gi, '_')
  const csvFiles = {}
  _.forEach(event.JsonToCSVResp, (item) => {
    const itemkey = Object.keys(item)[0]
    const [fileCommonKey, AttributeName] = itemkey.split('.')
    if (!csvFiles[`${fileCommonKey}`]) {
      csvFiles[`${fileCommonKey}`] = {}
    }
    csvFiles[`${fileCommonKey}`][`${AttributeName}`] = item[itemkey]
  })
  let loadResponse = await Promise.all(
    Object.keys(csvFiles).map(async (fileKey) => {
      console.log(`filekey: ${fileKey}`)
      const output = {}
      const jsonObjName = csvFiles[fileKey].JsonObjectName.replace(/-/gi, '_')
      let params = {
        S3DataFilePath: csvFiles[fileKey].csvFileName, // csv file name
        TableNamePrefix: csvFiles[fileKey].JsonObjectName.includes(
          event.DynamoTableName.toLowerCase()
        )
          ? tblName
          : `${tblName}_${jsonObjName}`, //table prefix
      }
      Object.assign(params, _.cloneDeep(event.CSVToPostgres))
      params.S3Options.S3OutputKeyPrefix = `${event.CSVToPostgres.S3Options.S3OutputKeyPrefix}${
        params.TableNamePrefix
      }-`
      console.log(`CSV to Postgres Params: ${JSON.stringify(params, null, 2)}`)
      const obj = new CsvToPostgres(params)
      output[fileKey] = await obj.LoadData()
      return output
    })
  )
  console.log('CSV to Postgres Response', JSON.stringify(loadResponse, null, 2))
  return loadResponse
}

async function ClearTestFiles(event) {}

// const event = require('./event')
// event.JsonToCSVResp = [
//   {
//     'S3CSVFile0.JsonObjectName': '0-int-ods-testtable-1',
//   },
//   {
//     'S3CSVFile0.csvFileName':
//       's3://int-ods-data/unit-test/testtable-1/data760/CSVFile-0-int-ods-testtable-1.csv',
//   },
//   {
//     'S3CSVFile1.JsonObjectName': '1-Benefits',
//   },
//   {
//     'S3CSVFile1.csvFileName':
//       's3://int-ods-data/unit-test/testtable-1/data760/CSVFile-1-Benefits.csv',
//   },
//   {
//     'S3CSVFile2.JsonObjectName': '2-Config',
//   },
//   {
//     'S3CSVFile2.csvFileName':
//       's3://int-ods-data/unit-test/testtable-1/data760/CSVFile-2-Config.csv',
//   },
//   {
//     'S3CSVFile3.JsonObjectName': '3-AdminFee',
//   },
//   {
//     'S3CSVFile3.csvFileName':
//       's3://int-ods-data/unit-test/testtable-1/data760/CSVFile-3-AdminFee.csv',
//   },
// ]

// Step6_CSVtoPostgres(event)
//   .then((res) => console.log(`res:${JSON.stringify(res, null, 2)}`))
//   .catch((err) => {
//     console.log(`err: ${JSON.stringify(err, null, 2)}`)
//   })
const PreStageToStageTables = {
  S3CSVFile0: {
    JsonObjectName: '0-ods-testtable-1',
    StageTablePrefix: 'ods_testtable_1_ods_testtable_1',
    Index: 0,
    S3OuputPrefix: 'dynamodb/ods-testtable-1/168094/168095-168100-StgDB--0-ods-testtable-1-db',
    JsonSchemaPath: 'ods-testtable-1',
    PreStageTableName: 'raw.ods_testtable_1168099_0_odstesttable1_190131_135213',
  },
  S3CSVFile1: {
    JsonObjectName: '1-Benefits',
    StageTablePrefix: 'ods_testtable_1_Benefits',
    Index: 1,
    S3OuputPrefix: 'dynamodb/ods-testtable-1/168094/168095-168100-StgDB--1-Benefits-db',
    JsonSchemaPath: 'ods-testtable-1.Benefits',
    PreStageTableName: 'raw.ods_testtable_1168099_1_Benefits_190131_135213',
  },
  S3CSVFile2: {
    JsonObjectName: '2-Config',
    StageTablePrefix: 'ods_testtable_1_Config',
    Index: 2,
    S3OuputPrefix: 'dynamodb/ods-testtable-1/168094/168095-168100-StgDB--2-Config-db',
    JsonSchemaPath: 'ods-testtable-1.Benefits.Config',
    PreStageTableName: 'raw.ods_testtable_1168099_2_Config_190131_135213',
  },
  S3CSVFile3: {
    JsonObjectName: '3-AdminFee',
    StageTablePrefix: 'ods_testtable_1_AdminFee',
    Index: 3,
    S3OuputPrefix: 'dynamodb/ods-testtable-1/168094/168095-168100-StgDB--3-AdminFee-db',
    JsonSchemaPath: 'ods-testtable-1.Benefits.Config.AdminFee',
    PreStageTableName: 'raw.ods_testtable_1168099_3_AdminFee_190131_135213',
  },
}

const CSVtoPostgresResponse = [
  {
    S3CSVFile0: {
      S3JsonSchemaFilePath:
        's3://int-ods-data/unit-test/testtable-1/data760/dbschema-testtable_1-json-bycsv-20190129_112153252.json',
      S3DBSchemaFilePath:
        's3://int-ods-data/unit-test/testtable-1/data760/dbschema-testtable_1-db-raw-20190129_112153448.sql',
      PreStageTableName: 'raw.testtable_1_44_190129_112153',
      TableCreated: true,
      RowCount: 1,
    },
  },
  {
    S3CSVFile1: {
      S3JsonSchemaFilePath:
        's3://int-ods-data/unit-test/testtable-1/data760/dbschema-testtable_1_1_Benefits-json-bycsv-20190129_112153248.json',
      S3DBSchemaFilePath:
        's3://int-ods-data/unit-test/testtable-1/data760/dbschema-testtable_1_1_Benefits-db-raw-20190129_112153432.sql',
      PreStageTableName: 'raw.testtable_1_1_Benefits_44_190129_112153',
      TableCreated: true,
      RowCount: 1,
    },
  },
  {
    S3CSVFile2: {
      S3JsonSchemaFilePath:
        's3://int-ods-data/unit-test/testtable-1/data760/dbschema-testtable_1_2_Config-json-bycsv-20190129_112153259.json',
      S3DBSchemaFilePath:
        's3://int-ods-data/unit-test/testtable-1/data760/dbschema-testtable_1_2_Config-db-raw-20190129_112153436.sql',
      PreStageTableName: 'raw.testtable_1_2_Config_44_190129_112153',
      TableCreated: true,
      RowCount: 1,
    },
  },
  {
    S3CSVFile3: {
      S3JsonSchemaFilePath:
        's3://int-ods-data/unit-test/testtable-1/data760/dbschema-testtable_1_3_AdminFee-json-bycsv-20190129_112153284.json',
      S3DBSchemaFilePath:
        's3://int-ods-data/unit-test/testtable-1/data760/dbschema-testtable_1_3_AdminFee-db-raw-20190129_112153459.sql',
      PreStageTableName: 'raw.testtable_1_3_AdminFee_44_190129_112153',
      TableCreated: true,
      RowCount: 1,
    },
  },
]
