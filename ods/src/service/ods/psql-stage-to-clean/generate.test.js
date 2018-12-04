import { DoTaskStageToClean } from './index'
import { getAndSetVarsFromEnvFile } from '../../../../env'
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue'
import { ODSPipeLineFactory } from '../PipeLineTaskFactory/index'

describe('DoTaskStageToClean - Unit Tests', () => {
  it.only('DoTaskStageToClean should return Success', async () => {
    getAndSetVarsFromEnvFile(false)
    const task = require('./event.json')
    // get connection string
    const dpTask = new DataPipeLineTaskQueue(task)
    dpTask.TableName = task.TableName
    try {
      expect.assertions(1)
      const resp = await ODSPipeLineFactory(DoTaskStageToClean)(dpTask)
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
      expect(resp.Status).toEqual('success')
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
})
