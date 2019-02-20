import { JsonToPSQL } from '.'
import { getAndSetVarsFromEnvFile } from '../../../../env'

const eventJson = require('./event.json')
const paramJson = {
  TableName: eventJson.TableName,
}
process.argv.forEach((val, index) => {
  console.log(`Node Command Line Parameters: ${index}: ${val}`)
})

if (process.argv && process.argv.length > 2 && process.argv[2] && process.argv[2].length > 0) {
  console.log(`Table to process as per command line Args: ${process.argv[2]}`)
  paramJson.TableName = process.argv[2]
}
console.log(`Event: ${JSON.stringify(paramJson, null, 2)}`)
console.log(`stage:${process.env.STAGE}, STAGE: ${process.env.STAGE}`)
console.time('JsonToPsql')
getAndSetVarsFromEnvFile(false)
JsonToPSQL(paramJson)
  .then((res) => {
    console.log('result:', JSON.stringify(res, null, 2))
    console.timeEnd('JsonToPsql')
  })
  .catch((err) => {
    console.error('error in json to psq:', err.message)
    console.timeEnd('JsonToPsql')
  })

//STAGE=int node lib/service/ods/json-to-psql/generate.test.js ods-testtable-1
