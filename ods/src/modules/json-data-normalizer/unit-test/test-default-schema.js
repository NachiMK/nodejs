import { ExtractOnlyMatchingKey } from '../index'

const dataInSchemaFile = require('./schema.json')
const dataInExpectedFile = require('./expected.json')

function testGetDefaultSchema() {
  const respSchema = ExtractOnlyMatchingKey(dataInSchemaFile, undefined, 'default')
  console.log('results:', JSON.stringify(respSchema, null, 2))
  console.log('Expected:', JSON.stringify(dataInExpectedFile, null, 2))
  if (JSON.stringify(respSchema, null, 2) === JSON.stringify(dataInExpectedFile, null, 2)) {
    console.log('Success')
  } else {
    console.log('Doesnt match with expected schema')
  }
}

testGetDefaultSchema()
