import isUndefined from 'lodash/isUndefined'
import isArray from 'lodash/isArray'
import {
  UpdatePipeLineTaskStatus as dataUpdatePipeLineTaskStatus,
  GetPipeLineTaskQueueAttribute as dataGetTaskQueueAttribute,
  GetPipeLineTaskStatus as dataGetTaskStatus,
} from '../../../data/ODSConfig/DataPipeLineTask'
import { TaskStatusEnum } from '../../ODSConstants'

export class DataPipeLineTaskQueue {
  constructor(task = {}) {
    this._dataPipeLineTaskQueueId = task.DataPipeLineTaskQueueId || -1
    this._taskConfigName = task.TaskConfigName || '~UNKNOWN.1'
    this._runSequence = task.RunSequence
    this._taskStatus = task.Status
    this._taskQueueAttributes = {}
    Object.assign(this._taskQueueAttributes, task.attributes)
    this.taskError = {}
  }
  get DataPipeLineTaskQueueId() {
    return this._dataPipeLineTaskQueueId
  }
  get TaskConfigName() {
    return this._taskConfigName
  }
  get TaskStatus() {
    return this._taskStatus
  }
  get RunSequence() {
    return this._runSequence
  }
  set TaskError(err) {
    this.taskError = err
  }
  get TaskError() {
    return this.taskError
  }
  set TaskQueueAttributes(attributes = {}) {
    if (!isUndefined(attributes) && isArray(attributes)) {
      attributes.forEach((item) => {
        this._taskQueueAttributes[item.AttributeName] = item.AttributeValue
      })
    }
  }
  get TaskQueueAttributes() {
    return this._taskQueueAttributes
  }
  getTaskAttributeValue(attributeName) {
    let retVal
    if (this.TaskQueueAttributes) {
      if (this.TaskQueueAttributes[attributeName]) {
        retVal = this.TaskQueueAttributes[attributeName]
      }
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
      await this.updateTaskStatus(TaskStatusEnum.Processing.name, undefined)
      processStatusResp.NewStatus = this.TaskStatus
      processStatusResp.Picked = true
    }
    return processStatusResp
  }

  async updateTaskStatus(status, err = {}) {
    // Seems redundant, because the caller sends this from the same attribute
    // this.TaskQueueAttributes = attributes
    const updateparams = {
      Status: status,
      Error: err,
    }
    Object.assign(updateparams, this.TaskQueueAttributes || {})
    await dataUpdatePipeLineTaskStatus(this.DataPipeLineTaskQueueId, updateparams)
    // if successfully updated then update my status.
    this._taskStatus = status
    this.TaskError = err
  }

  async loadAttributes() {
    // do something
    const resp = await dataGetTaskQueueAttribute(this.DataPipeLineTaskQueueId)
    if (!isUndefined(resp)) {
      this.TaskQueueAttributes = resp
    }
  }
}
