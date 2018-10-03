import { DoTaskPreStageToStage } from './index'
import { getAndSetVarsFromEnvFile } from '../../../../env'
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue'
import { ODSPipeLineFactory } from '../PipeLineTaskFactory/index'

async function TestDoTaskPreStageToStage() {
  getAndSetVarsFromEnvFile(false)
  const task = require('./event.json')
  // get connection string
  const dpTask = new DataPipeLineTaskQueue(task)
  dpTask.TableName = task.TableName
  const resp = await ODSPipeLineFactory(DoTaskPreStageToStage)(dpTask)
  console.log('resp', JSON.stringify(resp, null, 2))
  return resp
}

TestDoTaskPreStageToStage()
  .then((result) => console.log('result:', JSON.stringify(result, null, 2)))
  .catch((err) => console.log('err:', JSON.stringify(err, null, 2)))
