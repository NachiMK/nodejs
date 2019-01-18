import { exportDynamoTable } from './dynamo-table-s3'
import { exportMultipleTables } from './export-mulitple-table'

// npm run build && clear && jest src/modules/dynamo-table-to-s3/generate-test.js
describe('dyanmo-table-initial Load - Unit Tests', () => {
  it.skip('Single Table - should return Success', async () => {
    console.time(`dynamo-export`)
    const eventData = require('./event.json')
    try {
      expect.assertions(1)
      // get connection string
      const resp = await exportDynamoTable(eventData)
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      expect(err).toBeUndefined()
    }
    console.timeEnd(`dynamo-export`)
  })
  it.only('Multiple Table - should return Success', async () => {
    const eventData = require('./multiple-table-event.json')
    try {
      expect.assertions(1)
      // get connection string
      const resp = await exportMultipleTables(eventData)
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      expect(err).toBeUndefined()
    }
  })
})
