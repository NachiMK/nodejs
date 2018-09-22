import odsLogger from '../../modules/log/ODSLogger'
import { getConnectionString } from '../../data/psql'

export class OdsPreStageToStage {
  constructor(dataPipeLineTask) {
    this._dataPipeLineTask = dataPipeLineTask
  }

  get DataPipeLineTask() {
    return this._dataPipeLineTask
  }
  get TaskAttributes() {
    return this.DataPipeLineTask.TaskQueueAttributes
  }

  async StageData() {
    this.ValidateParam()
    const retResp = {}
    try {
      retResp.status.message = 'processing'
      this.GetStageTableScript()
      this.ApplyScriptsToDB()
      this.CopyDataToState()
    } catch (err) {
      const e = new Error(`Error in copying data to stage table, ${err.message}`)
      retResp.error = e
      retResp.status.message = 'error'
      throw e
    }
    return retResp
  }

  GetStageTableScript() {
    try {
      // do something
      const input = {
        S3JsonSchemaFilePath: '',
        TableName: '',
        DropTableAndCreate: false,
        TableSchema: '',
        IgnoreColumns: [],
        DBConnection: '',
        Options: {
          SaveScript: true,
          S3OutputBucket: '',
          S3OutputPrefix: '',
          AppendDateTimeToFile: '',
          FileExtension: '.sql',
        },
      }
    } catch (err) {
      throw new Error(`Error in getting Stage table script: ${err.message}`)
    }
  }

  ApplyScriptsToDB() {
    try {
      // do something
    } catch (err) {
      throw new Error(`Error in ApplyScriptsToDB: ${err.message}`)
    }
  }

  CopyDataToState() {
    try {
      // do something
    } catch (err) {
      throw new Error(`Error in CopyDataToState script: ${err.message}`)
    }
  }

  ValidateParam() {
    if (!this.DataPipeLineTask) {
      throw new Error(`InValidParam. DataPipeLineTask is required.`)
    }
  }
}
