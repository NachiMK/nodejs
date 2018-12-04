import { DoTaskStageToClean } from './index'
import { getAndSetVarsFromEnvFile } from '../../../../env'
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue'
import { ODSPipeLineFactory } from '../PipeLineTaskFactory/index'

async function TestDoTaskStageToClean() {
  getAndSetVarsFromEnvFile(false)
  const task = require('./event.json')
  // get connection string
  const dpTask = new DataPipeLineTaskQueue(task)
  dpTask.TableName = task.TableName
  const resp = await ODSPipeLineFactory(DoTaskStageToClean)(dpTask)
  console.log('resp', JSON.stringify(resp, null, 2))
  return resp
}

TestDoTaskStageToClean()
  .then((result) => console.log('DoTaskStageToClean result:', JSON.stringify(result, null, 2)))
  .catch((err) => console.log('DoTaskStageToClean err:', JSON.stringify(err, null, 2)))
