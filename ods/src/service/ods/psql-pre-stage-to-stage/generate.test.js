import { DoTaskPreStageToStage } from './index'
import { getAndSetVarsFromEnvFile } from '../../../../env'
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue'
import { ODSPipeLineFactory } from '../PipeLineTaskFactory/index'

describe('DoTaskPreStageToStage - Unit Tests', () => {
  it.only(
    'DoTaskPreStageToStage should return Success',
    async () => {
      getAndSetVarsFromEnvFile(false)
      const task = require('./event.json')
      // get connection string
      const dpTask = new DataPipeLineTaskQueue(task)
      dpTask.TableName = task.TableName
      const resp = await ODSPipeLineFactory(DoTaskPreStageToStage)(dpTask)
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
      expect(resp.Status).toEqual('success')
    },
    30000
  )
})
