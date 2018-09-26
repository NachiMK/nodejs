import odsLogger from '../../modules/log/ODSLogger'
import { getConnectionString } from '../../data/psql'
import {
  DynamicAttributeEnum,
  PreDefinedAttributeEnum,
} from '../../modules/ODSConstants/AttributeNames'

const JsonObjectNameEnum = DynamicAttributeEnum.JsonObjectName.value
const PreStageTableEnum = DynamicAttributeEnum.PreStageTableName.value
const S3SchemaFileBucketName = PreDefinedAttributeEnum.S3SchemaFileBucketName.value
const StageTablePrefix = 'StageTablePrefix'
const S3SchemaFileEnum = PreDefinedAttributeEnum.S3SchemaFile.value
const SaveIntermediateResultsEnum = PreDefinedAttributeEnum.SaveIntermediateResults.value

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

  get TablesToStage() {
    const regExJ = new RegExp(JsonObjectNameEnum, 'gi')
    const regExT = new RegExp(PreStageTableEnum, 'gi')
    if (this.TaskAttributes) {
      const filtered = pickBy(this.TaskAttributes, function(attvalue, attkey) {
        // Attribute name should in format: S3CSVFile1.CSVFileName or S3CSVFile1.JsonObjectName
        return (
          attkey.match(/S3CSVFile\d+\.{1}.*/gi) && (attkey.match(regExJ) || attkey.match(regExT))
        )
      })
      // Every file has two different information, File name and Json
      // we are going to combine that into one object
      const retCollection = {}
      Object.keys(filtered).map((item) => {
        const [fileCommonKey, AttributeName] = item.split('.')
        if (!retCollection[`${fileCommonKey}`]) {
          retCollection[`${fileCommonKey}`] = {}
        }
        if (AttributeName.match(regExJ)) {
          retCollection[`${fileCommonKey}`][`${StageTablePrefix}`] =
            filtered[item][`${JsonObjectNameEnum}`]
        } else if (AttributeName.match(regExT)) {
          retCollection[`${fileCommonKey}`][`${PreStageTableEnum}`] =
            filtered[item][`${PreStageTableEnum}`]
        }
      })
      return retCollection
    }
    return {}
  }

  async StageData() {
    this.ValidateParam()
    const retResp = {}
    try {
      retResp.status.message = 'processing'
      const tables = this.TablesToStage()
      const tableResults = await Promise.all(
        tables.map(async (table) => {
          const retVal = {}
          retVal[`${table.StageTablePrefix}`] = {}
          const s3filePath = await this.GetStageTableScript(table)
          retVal[`${table.StageTablePrefix}`].TableScriptCreated = true
          // const tblName = await this.ApplyScriptsToDB(table)
          retVal[`${table.StageTablePrefix}`].TableCreated = true
          // const RowCount = await this.CopyDataToState(table)
          retVal[`${table.StageTablePrefix}`].DataCopied = true
          return retVal
        })
      )
    } catch (err) {
      const e = new Error(`Error in copying data to stage table, ${err.message}`)
      retResp.error = e
      retResp.status.message = 'error'
      throw e
    }
    return retResp
  }

  async GetStageTableScript(table) {
    try {
      const objParams = {
        TableNamePrefix: table[StageTablePrefix],
        BatchId: this.DataPipeLineTask.DataPipeLineTaskQueueId,
        DBOptions: {
          TableSchema: 'stg',
          DataTypeKey: 'db_type',
          IgnoreColumns: [],
          AppendDateTimeToTable: false,
          AppendBatchId: false,
        },
      }

      if (this.TaskAttributes[SaveIntermediateResultsEnum]) {
        objParams.S3DataFilePath = ''
        objParams.S3OutputBucket = this.TaskAttributes[S3SchemaFileBucketName]
        objParams.S3OutputKeyPrefix = `${table[StageTablePrefix]}-db-stg-`
        objParams.Options = {
          FileExtension: '.sql',
          AppendDateTimeToFileName: true,
        }
      }

      const objDBScriptGen = new JsonSchemaToDBSchema(objParams)
      const jsonschema = await this.getTableJsonSchema(
        this.TaskAttributes[S3SchemaFileEnum],
        table[StageTablePrefix]
      )
      // get script
      this._dbScript = await objDBScriptGen.getDBScriptFromJsonSchema({
        JsonSchema: jsonschema,
      })
      this._outputTableSchema = objDBScriptGen.TableSchema
      this._outputTableName = objDBScriptGen.OutputTableName
      // save file
      if (this.S3Options._saveIntermediatFilesToS3) {
        const s3filepath = await objDBScriptGen.saveDBSchema(this._dbScript)
        return s3filepath
      }
    } catch (err) {
      throw new Error(`Error in getting Stage table script: ${err.message}`)
    }
  }

  async ApplyScriptsToDB() {
    try {
      // do something
    } catch (err) {
      throw new Error(`Error in ApplyScriptsToDB: ${err.message}`)
    }
  }

  async CopyDataToState() {
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
