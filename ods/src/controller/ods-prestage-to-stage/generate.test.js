import { OdsPreStageToStage } from './index'
import { getAndSetVarsFromEnvFile } from '../../../env'
import { DataPipeLineTaskQueue } from '../../modules/ODSConfig/DataPipeLineTaskQueue/index'

describe('OdsPreStageToStage - Unit Tests', () => {
  it.only('OdsPreStageToStage Unit test', async () => {
    getAndSetVarsFromEnvFile(false)
    const task = require('./event.json')
    const dataPipeLineTaskQueue = new DataPipeLineTaskQueue(task)
    expect.assertions(1)
    const processStatusResp = await dataPipeLineTaskQueue.PickUpTask(true)
    expect(processStatusResp.Picked).toBeDefined()
    const objPreStageToStage = new OdsPreStageToStage(dataPipeLineTaskQueue)
    expect.assertions(1)
    try {
      const stgResp = await objPreStageToStage.StageData()
      expect(stgResp).toBeDefined()
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
})
