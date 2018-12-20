import { exportDynamoTable } from './dynamo-table-s3'

const eventData = require('./event.json')

console.time(`dynamo-export`)
exportDynamoTable(eventData)
  .then((res) => {
    console.log(`Results: ${JSON.stringify(res, null, 2)}`)
    console.timeEnd(`dynamo-export`)
  })
  .catch((err) => {
    console.log(`Error: ${JSON.stringify(err, null, 2)}`)
    console.timeEnd(`dynamo-export`)
  })

// npm run build && clear && node lib/modules/dynamo-table-to-s3/generate-test.js
