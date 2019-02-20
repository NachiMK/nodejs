import { DoTaskJsonToCSV } from './index'
import { getAndSetVarsFromEnvFile } from '../../../../env'
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue'
import { ODSPipeLineFactory } from '../PipeLineTaskFactory/index'

describe('DoTaskJsonToCSV - Unit Tests', () => {
  it.only('DoTaskJsonToCSV should return success', async () => {
    getAndSetVarsFromEnvFile(false)
    const task = require('./event.json')
    // get connection string
    const dpTask = new DataPipeLineTaskQueue(task)
    dpTask.TableName = task.TableName
    // await dpTask.loadAttributes()
    expect.assertions(3)
    const resp = await ODSPipeLineFactory(DoTaskJsonToCSV)(dpTask)
    // const resp = await DoTaskJsonToCSV(dpTask)
    console.log('resp', JSON.stringify(resp, null, 2))
    expect(resp).toBeDefined()
    expect(dpTask.TaskQueueAttributes).toBeDefined()
    expect(resp.Status).toEqual('success')
  })
})
