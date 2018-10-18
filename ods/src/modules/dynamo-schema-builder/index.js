import { generateSchemaByData } from '../json-schema-utils/index'

const awsSDK = require('aws-sdk')
const table = require('@hixme/tables')
const _ = require('lodash')

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
      return generateSchemaByData(key, dataForPartition, { SimpleArraysToObjects: true })
    })
  } else {
    const schema = generateSchemaByData(tableName, data, { SimpleArraysToObjects: true })
    schemas.push(schema)
  }

  let schemString = ''
  schemas.forEach((s) => {
    schemString += JSON.stringify(s.schema)
    // console.log('s.schema', JSON.stringify(s.schema, null, 2));
  })

  return schemString
}
