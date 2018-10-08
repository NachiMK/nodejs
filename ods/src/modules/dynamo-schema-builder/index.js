import { json as hixmeSchemaGenerator } from '@hixme/generate-schema'

const awsSDK = require('aws-sdk')
const table = require('@hixme/tables')
const _ = require('lodash')
// const generator = require('@hixme/generate-schema');

awsSDK.config.update({
  region: 'us-west-2',
  endpoint: 'https://dynamodb.us-west-2.amazonaws.com',
})

table.config({
  tablePrefix: '',
  debug: false,
  generateLengths: false,
})

export async function GetDynamoTableSchema(event = {}) {
  console.log('event', event)
  const retResp = {}
  try {
    const schema = await generateTableSchema(event.TableName)
    // console.log('schema', JSON.stringify(schema, null, 2));
    if (schema && schema.length > 0) {
      retResp.Status = 'success'
      retResp.Schema = schema
    }
  } catch (err) {
    retResp.Status = 'error'
    retResp.error = new Error(
      `Error generating Table Schema for Table: ${event.TableName}, ${err.message}`
    )
    retResp.Schema = undefined
    console.error(retResp.error.message)
    throw retResp.error
  }
  return retResp
}

const generateTableSchema = async (tableName, options = {}) => {
  const theTable = table.create(tableName)

  // this might take a while. TODO: Optimize this part.
  const data = await theTable.getAll()
  let schemas = []

  if (options && options.partitionKey) {
    const dataByPartition = _.groupBy(data, options.partitionKey)

    schemas = Object.keys(dataByPartition).map((key) => {
      const dataForPartition = dataByPartition[key]
      // Generate schema for each partition
      return generateSchemaByData(key, dataForPartition)
    })
  } else {
    const schema = generateSchemaByData(tableName, data)
    schemas.push(schema)
  }

  let schemString = ''
  schemas.forEach((s) => {
    schemString += JSON.stringify(s.schema)
    // console.log('s.schema', JSON.stringify(s.schema, null, 2));
  })

  return schemString
}

export function generateSchemaByData(name, data) {
  let schema = {}
  try {
    console.log('About to generate schema for:', name)
    schema = hixmeSchemaGenerator(name, data, {
      generateEnums: false,
      maxEnumValues: 0,
      generateLengths: false,
    })
  } catch (err) {
    schema = {}
    console.error('Error calling hixme generator', JSON.stringify(err, null, 2))
    throw new Error(`Error calling hixme generator: ${JSON.stringify(err, null, 2)}`)
  }

  // Remove the array of items from top and just leave object
  return { name, schema: { $schema: schema.$schema, ...schema.items } }
}
