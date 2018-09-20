import { DoTaskCsvToPreStage } from './index'
import { getAndSetVarsFromEnvFile } from '../../../../env'
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue'

describe('DoTaskCsvToPreStage - Unit Tests', () => {
  it.only(
    'DoTaskCsvToPreStage should return Success',
    async () => {
      getAndSetVarsFromEnvFile(false)
      const task = require('./event.json')
      // get connection string
      const dpTask = new DataPipeLineTaskQueue(task)
      await dpTask.PickUpTask(true)
      const resp = await DoTaskCsvToPreStage(dpTask)
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
      expect(resp.Status).toEqual('Completed')
    },
    30000
  )
})
