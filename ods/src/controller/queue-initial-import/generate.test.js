import { queueInitialImport } from './queue-initial-import'
import { getAndSetVarsFromEnvFile } from '../../../env'

const event = require('./clients-event.json')

describe('queue-initial-import - Unit Tests', () => {
  it.only('queue-initial-import Unit test', async () => {
    getAndSetVarsFromEnvFile(false)
    try {
      expect.assertions(1)
      const importResp = await queueInitialImport(event)
      console.log(`importResp: ${JSON.stringify(importResp, null, 2)}`)
      expect(importResp).toBeDefined()
      expect(_.isArray(importResp)).toBe(true)
      expect(_.size(importResp)).toBe(1)
      expect(importResp[0].DataPipeLineInitialImportId).toBeGreaterThan(0)
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
})
