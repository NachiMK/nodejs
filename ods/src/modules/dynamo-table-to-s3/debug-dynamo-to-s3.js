import { exportDynamoTable } from './dynamo-table-s3'

console.time(`dynamo-export`)
const eventData = require('./event.json')
// get connection string
exportDynamoTable(eventData)
  .then((res) => {
    console.log('resp', JSON.stringify(res, null, 2))
    console.timeEnd(`dynamo-export`)
  })
  .catch((err) => {
    console.timeEnd(`dynamo-export`)
    console.error(`Error: ${JSON.stringify(err)}`)
  })
