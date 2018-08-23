import {
  UpdatePipeLineTaskStatus as dataUpdatePipeLineTaskStatus,
  GetPipeLineTaskQueueAttribute as dataGetTaskQueueAttribute,
  GetPipeLineTaskStatus as dataGetTaskStatus,
} from '../../../data/ODSConfig/DataPipeLineTask'
import { TaskStatusEnum } from '../../ODSConstants'

export class DataPipeLineTaskQueue {
  constructor(task = {}) {
    this.dataPipeLineTaskQueueId = task.DataPipeLineTaskQueueId || -1
    this.taskConfigName = task.TaskConfigName || '~UNKNOWN.1'
    this.runSequence = task.RunSequence
    this.taskStatus = task.Status
    this.taskQueueAttributes = {}
    Object.assign(this.taskQueueAttributes, task.attributes)
    this.taskError = {}
  }
  get DataPipeLineTaskQueueId() {
    return this.dataPipeLineTaskQueueId
  }
  get TaskConfigName() {
    return this.taskConfigName
  }
  get TaskStatus() {
    return this.taskStatus
  }
  get RunSequence() {
    return this.runSequence
  }
  set TaskError(err) {
    this.taskError = err
  }
  get TaskError() {
    return this.taskError
  }
  set TaskQueueAttributes(attributes = {}) {
    if (attributes && attributes instanceof Array) {
      attributes.forEach((item) => {
        this.taskQueueAttributes[item.AttributeName] = item.AttributeValue
      })
    }
    // Object.assign(this.taskQueueAttributes, attributes);
  }
  get TaskQueueAttributes() {
    return this.taskQueueAttributes
  }
  getTaskAttributeValue(attributeName) {
    let retVal
    if (this.taskQueueAttributes) {
      if (this.taskQueueAttributes[attributeName]) retVal = this.taskQueueAttributes[attributeName]
    }
    return retVal
  }

  async getTaskStatus() {
    return dataGetTaskStatus(this.DataPipeLineTaskQueueId)
  }

  async PickUpTask(RefreshAttributes = false) {
    const processStatusResp = {}
    processStatusResp.ExistingTaskStatus = await this.getTaskStatus()
    processStatusResp.Picked = false
    processStatusResp.NewStatus = undefined
    if (processStatusResp && processStatusResp.ExistingTaskStatus === TaskStatusEnum.Ready.name) {
      // refresh attributes if needed
      if (RefreshAttributes === true) await this.loadAttributes()
      // Update task as picked up
      await this.updateTaskStatus(TaskStatusEnum.Processing.name, undefined, undefined)
      processStatusResp.NewStatus = this.TaskStatus
      processStatusResp.Picked = true
    }
    return processStatusResp
  }

  async updateTaskStatus(status, err = {}, attributes = {}) {
    // do something
    this.TaskQueueAttributes = attributes
    const updateparams = {
      Status: status,
      Error: err,
    }
    Object.assign(updateparams, attributes)
    await dataUpdatePipeLineTaskStatus(this.dataPipeLineTaskQueueId, updateparams)
    // if successfully updated then update my status.
    this.taskStatus = status
    this.TaskError = err
  }

  async loadAttributes() {
    // do something
    const resp = await dataGetTaskQueueAttribute(this.dataPipeLineTaskQueueId)
    if (resp && resp instanceof Object) {
      this.TaskQueueAttributes = resp
    }
  }
}
