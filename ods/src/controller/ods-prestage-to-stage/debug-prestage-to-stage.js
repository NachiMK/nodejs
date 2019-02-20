import { OdsPreStageToStage } from './index'
import { getAndSetVarsFromEnvFile } from '../../../env'
import { DataPipeLineTaskQueue } from '../../modules/ODSConfig/DataPipeLineTaskQueue/index'

async function testPreStageToStage() {
  getAndSetVarsFromEnvFile(false)
  const task = require('./event.json')
  const dataPipeLineTaskQueue = new DataPipeLineTaskQueue(task)
  const processStatusResp = await dataPipeLineTaskQueue.PickUpTask(true)
  console.log(`Picked? ${processStatusResp.Picked}`)
  const objPreStageToStage = new OdsPreStageToStage(dataPipeLineTaskQueue)
  try {
    const stgResp = await objPreStageToStage.StageData()
    console.log(`stgResp: ${JSON.stringify(stgResp, null, 2)}`)
    return stgResp
  } catch (err) {
    console.log('error', err.message)
    throw err
  }
}

testPreStageToStage()
  .then((resp) => console.log(`resp: ${JSON.stringify(resp, null, 2)}`))
  .catch((err) => {
    console.error(`error: ${err.message}`)
  })
