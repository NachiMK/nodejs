import { ODSStageToClean } from './index'
import { getAndSetVarsFromEnvFile } from '../../../env'
import { DataPipeLineTaskQueue } from '../../modules/ODSConfig/DataPipeLineTaskQueue/index'

describe('ODSStageToClean - Unit Tests', () => {
  it.only('ODSStageToClean Unit test', async () => {
    getAndSetVarsFromEnvFile(false)
    const task = require('./event.json')
    const dataPipeLineTaskQueue = new DataPipeLineTaskQueue(task)
    expect.assertions(2)
    const processStatusResp = await dataPipeLineTaskQueue.PickUpTask(true)
    expect(processStatusResp.Picked).toBeDefined()
    const objPreStageToStage = new ODSStageToClean(dataPipeLineTaskQueue)
    try {
      expect.assertions(1)
      const stgResp = await objPreStageToStage.LoadData()
      expect(stgResp).toBeDefined()
      console.log(`stgResp: ${JSON.stringify(stgResp, null, 2)}`)
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
})
