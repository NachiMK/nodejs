import { OdsCsvToPreStage } from './index'
import { getAndSetVarsFromEnvFile } from '../../../env'
import { DataPipeLineTaskQueue } from '../../modules/ODSConfig/DataPipeLineTaskQueue'

describe('OdsCsvToPreStage - Unit Tests', () => {
  it.only(
    'OdsCsvToPreStage should return Success',
    async () => {
      getAndSetVarsFromEnvFile(false)
      const task = require('./event.json')
      // get connection string
      const dpTask = new DataPipeLineTaskQueue(task)
      await dpTask.PickUpTask(true)
      const obj = new OdsCsvToPreStage(dpTask)
      const resp = await obj.SaveFilesToDatabase()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
      expect(resp.status.message).toEqual('SUCCESS')
    },
    30000
  )
  it.skip('OdsCsvToPreStage should throw Validation Error', async () => {
    const dpTask = new DataPipeLineTaskQueue(task)
    const obj = new OdsCsvToPreStage(dpTask)
    try {
      await obj.SaveFilesToDatabase()
    } catch (err) {
      expect(err).toBeDefined()
    }
  })
})
