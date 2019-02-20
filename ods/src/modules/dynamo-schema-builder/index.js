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
    //DATA-742
    const schema = await generateTableSchema(event.TableName, { GenerateLengths: true })
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
  //DATA-742
  let generateLengths = false
  if (options && !_.isUndefined(options.GenerateLengths)) {
    generateLengths = options.GenerateLengths || false
  }

  if (options && options.partitionKey) {
    const dataByPartition = _.groupBy(data, options.partitionKey)

    schemas = Object.keys(dataByPartition).map((key) => {
      const dataForPartition = dataByPartition[key]
      // Generate schema for each partition
      //DATA-742
      return generateSchemaByData(key, dataForPartition, {
        GenerateLengths: generateLengths,
        SimpleArraysToObjects: true,
      })
    })
  } else {
    //DATA-742
    const schema = generateSchemaByData(tableName, data, {
      GenerateLengths: generateLengths,
      SimpleArraysToObjects: true,
    })
    schemas.push(schema)
  }

  let schemString = ''
  schemas.forEach((s) => {
    schemString += JSON.stringify(s.schema)
    // console.log('s.schema', JSON.stringify(s.schema, null, 2));
  })

  return schemString
}
