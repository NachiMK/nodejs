import { ODSStageToClean } from './index'
import { getAndSetVarsFromEnvFile } from '../../../env'
import { DataPipeLineTaskQueue } from '../../modules/ODSConfig/DataPipeLineTaskQueue/index'

async function DebugStageToClean() {
  getAndSetVarsFromEnvFile(false)
  const task = require('./event.json')
  const dataPipeLineTaskQueue = new DataPipeLineTaskQueue(task)
  const processStatusResp = await dataPipeLineTaskQueue.PickUpTask(true)
  console.log(`Picked?: ${processStatusResp.Picked}`)
  const objStageToClean = new ODSStageToClean(dataPipeLineTaskQueue)
  try {
    const stgResp = await objStageToClean.LoadData()
    return stgResp
  } catch (err) {
    console.log('error', err.message)
    throw err
  }
}

DebugStageToClean()
  .then((resp) => console.log(`resp: ${JSON.stringify(resp, null, 2)}`))
  .catch((err) => {
    console.error(`error: ${err.message}`)
  })
