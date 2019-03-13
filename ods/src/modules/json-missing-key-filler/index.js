import { format as _format, transports as _transports, createLogger } from 'winston'
import _ from 'lodash'
// import missingDeepKeys from 'missing-deep-keys'
import { GetJSONFromS3Path, SaveJsonToS3File } from '../s3ODS'
import { ExtractMatchingKeyFromSchema } from '../json-extract-matching-keys/index'
import fillMissingKeys from 'object-fill-missing-keys'
import { deleteByPath } from '../delete-json-objects-by-keys/delete-json-objects-by-keys'

export class JsonMissingKeyFiller {
  output = {
    status: {
      message: 'processing',
    },
    error: undefined,
    S3UniformJsonFile: undefined,
    UniformJsonData: undefined,
  }
  defaultSchema = undefined
  logger = createLogger({
    format: _format.combine(
      _format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss',
      }),
      _format.splat(),
      _format.prettyPrint()
    ),
  })

  constructor(params = {}) {
    this.s3SchemaFile = params.S3SchemaFile || ''
    this.jsonKeysToIgnore = params.JsonKeysToIgnore || ''
    this.s3DataFile = params.S3DataFile || ''
    this.s3OutputBucket = params.S3OutputBucket || ''
    this.s3OutputKey = params.S3OutputKey || ''
    this.loglevel = params.LogLevel || 'warn'
    this.doNotfillEmptyObjects = params.DoNotfillEmptyObjects || false
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel
    this.logger.add(this.consoleTransport)
  }
  get S3SchemaFile() {
    return this.s3SchemaFile
  }
  get JsonKeysToIgnore() {
    return this.jsonKeysToIgnore
  }
  get S3DataFile() {
    return this.s3DataFile
  }
  get ModuleError() {
    return this.output.error
  }
  get ModuleStatus() {
    return this.output.status.message
  }
  get Output() {
    return this.output
  }
  get S3UniformJsonFile() {
    return this.output.S3UniformJsonFile
  }
  get LogLevel() {
    return this.loglevel
  }
  get DefaultSchema() {
    return this.defaultSchema
  }
  get S3OutputBucket() {
    return this.s3OutputBucket
  }
  get S3OutputKey() {
    return this.s3OutputKey
  }
  get DoNotfillEmptyObjects() {
    return this.doNotfillEmptyObjects
  }
  ValidateParams() {
    if (_.isEmpty(this.S3SchemaFile)) {
      throw new Error('Invalid Param. Please pass a S3SchemaFile')
    }
    if (_.isEmpty(this.S3DataFile)) {
      throw new Error('Invalid Param. Please pass valid S3 Data File')
    }
  }
  async getUniformJsonData(ConvertSimpleArrayToObjects = true) {
    try {
      this.ValidateParams()
      const schemaFromS3 = await GetJSONFromS3Path(this.S3SchemaFile)
      let dataFromS3 = await GetJSONFromS3Path(this.S3DataFile)

      if (!schemaFromS3 || !dataFromS3) {
        throw new Error(
          `No data in Schema File: ${this.S3SchemaFile} or in Data File: ${this.S3DataFile}`
        )
      }

      // remove certain Json Objects we dont want to process
      if (this.JsonKeysToIgnore) {
        dataFromS3 = this.RemoveJsonObjectsByPath(dataFromS3, this.JsonKeysToIgnore)
      }

      if (ConvertSimpleArrayToObjects) {
        this.ReplaceSimpleArrayToObjects(dataFromS3)
      }

      // get default values for all keys
      this.defaultSchema = ExtractMatchingKeyFromSchema(schemaFromS3, 'default')
      this.logger.log('debug', JSON.stringify(this.DefaultSchema, null, 2))

      if (!this.DefaultSchema) {
        throw new Error(`Default Schema from File: ${schemaFromS3} couldn't be extracted`)
      }

      // add default values and missing keys for props missing in our data
      this.AddMissingKeys(dataFromS3, this.DoNotfillEmptyObjects)
      if (
        this.S3OutputBucket &&
        this.S3OutputKey &&
        this.S3OutputBucket.length > 0 &&
        this.S3OutputKey.length > 0
      ) {
        this.Output.S3UniformJsonFile = await SaveJsonToS3File(this.Output.UniformJsonData, {
          S3OutputBucket: this.S3OutputBucket,
          S3OutputKey: this.S3OutputKey,
        })
        // clear output if saving to s3
        delete this.Output.UniformJsonData
      }
      this.Output.status.message = 'success'
    } catch (err) {
      console.log(`Error in JsonDataNormalier: ${err.message}`)
      this.Output.status.message = 'error'
      this.Output.error = new Error(`Error in JsonDataNormalier: ${err.message}`)
      throw this.Output.error
    }
  }

  IsSimpleArray(arrayToTest) {
    let retval = false
    if (arrayToTest.length > 0) {
      let hasObject = false
      hasObject = arrayToTest.some((val) => val instanceof Object)
      retval = !hasObject
    }
    return retval
  }

  ReplaceSimpleArrayToObjects = (dataRows) => {
    if (dataRows) {
      // loop through recursively and replace arrays as objects
      _.forIn(dataRows, (row, key, parentRows) => {
        if (_.isObject(row)) {
          if (this.IsSimpleArray(row)) {
            // replace with objects
            const arrToObj = row.map((arrayItem, idx) => {
              return {
                ArrayIndex: idx,
                ArrayValue: arrayItem,
              }
            })
            parentRows[key] = arrToObj
          } else {
            // recurse
            this.ReplaceSimpleArrayToObjects(row)
          }
        }
      })
    }
  }

  RemoveJsonObjectsByPath = (dataRows, pathsToRemove) => {
    if (dataRows) {
      // remove by keys
      return deleteByPath({
        JsonData: dataRows,
        CommaSeparatedPaths: pathsToRemove,
        LogLevel: this.LogLevel,
      })
    }
  }

  AddMissingKeys = (dataRows, DoNotfillEmptyObjects = false) => {
    if (dataRows) {
      this.Output.UniformJsonData = dataRows.map((item) => {
        if (item.Item) return this.Filldefaults(item.Item, DoNotfillEmptyObjects)
        return this.Filldefaults(item, DoNotfillEmptyObjects)
      })
    }
    this.logger.log('debug', '---------------- FILLED ROWS ----------')
    this.logger.log('debug', JSON.stringify(this.Output.UniformJsonData, null, 2))
    this.logger.log('debug', '---------------- FILLED ROWS ----------')
  }

  Filldefaults(dataRow, DoNotfillEmptyObjects = false) {
    const result = fillMissingKeys(dataRow, this.DefaultSchema)
    this.DeleteNullObjectsArrays(result)
    if (DoNotfillEmptyObjects) {
      this.RemoveObjectsWithOnlyDefaultValues(result, dataRow)
    }
    return result
  }

  DeleteNullObjectsArrays(jsonRow) {
    if (jsonRow instanceof Object) {
      this.logger.log('debug', 'Deleting Null elements')
      Object.keys(jsonRow).forEach((prop) => {
        if (JSON.stringify(jsonRow[prop]).localeCompare('null') === 0) {
          delete jsonRow[prop]
        }
      })
    }
  }

  DeleteObjectByPath(targetJson, pathtoDelete) {
    this.logger.log('debug', `Path to Delete: ${pathtoDelete}`)
    if (targetJson && pathtoDelete) {
      const objToDel = _.get(targetJson, pathtoDelete)
      if (!_.isUndefined(objToDel)) {
        eval(`delete targetJson${pathtoDelete}`)
      }
    }
  }

  DeleteMissingObjects(targetObj, sourceObj, PathToTarget) {
    try {
      const target =
        !_.isUndefined(PathToTarget) && PathToTarget.length > 0
          ? eval(`targetObj${PathToTarget}`)
          : targetObj
      _.forIn(target, (rowValue, rowKey) => {
        // delete if present only in target and not in source
        if (
          _.isObject(target[rowKey]) &&
          // source is missing or empty
          (_.isUndefined(sourceObj[rowKey]) || _.isEmpty(sourceObj[rowKey]))
        ) {
          delete target[rowKey]
        }
      })
    } catch (err) {
      console.log(
        `Error: ${
          err.message
        }, targetObj: ${targetObj}, SourceObj: ${sourceObj}, PathToTarget: ${PathToTarget}`
      )
      throw new Error(`Error Deleting PathToTarget: ${PathToTarget}, error: ${err.message}`)
    }
  }

  RemoveObjectsWithOnlyDefaultValues(filledRows, OrigdataRow, PathToDataRow = '') {
    this.logger.log('debug', `OrigDataRow: ${OrigdataRow}, PathToDataRow: ${PathToDataRow}`)
    if (filledRows && OrigdataRow) {
      this.DeleteMissingObjects(filledRows, OrigdataRow, PathToDataRow)
      _.forIn(OrigdataRow, (rowValue, rowKey, rowParent) => {
        // const rowKey = Object.keys(row)[0]
        let myPath = `${PathToDataRow}["${rowKey}"]`
        this.logger.log('debug', `myPath: ${myPath}`)
        //do something
        if (_.isObject(rowParent[rowKey])) {
          this.logger.log('debug', `IsObject: ${true}`)
          // recurse
          if (_.isEmpty(rowValue)) {
            this.logger.log('debug', `IsEmpty: ${true}`)
            // find the object in FilledRows and delete it
            this.DeleteObjectByPath(filledRows, myPath)
          } else {
            this.logger.log('debug', `Recurse: ${true}`)
            this.RemoveObjectsWithOnlyDefaultValues(filledRows, rowValue, myPath)
          }
        } else if (_.isArray(rowParent[rowKey])) {
          this.logger.log('debug', `IsArray: ${true}`)
          // if array is empty delete in filled rows
          if (_.isEmpty(rowValue)) {
            this.logger.log('debug', `IsEmpty: ${true}`)
            // find the object in FilledRows and delete it
            this.DeleteObjectByPath(filledRows, myPath)
          } else {
            // if array has elements/objects then recurse
            const simpleItems = rowValue.every((arrItem) => {
              return !_.isObject(arrItem)
            })
            if (!simpleItems) {
              this.logger.log('debug', `Not Simple Items: ${true}`)
              // recurse the objects
              _.forEach(rowValue, (arrItem, idx) => {
                const myArrayPath = `${myPath}[${idx}]["${Object.keys(arrItem)[0]}"]`
                console.log(`Recurse: myArrayPath: ${myArrayPath}`)
                this.RemoveObjectsWithOnlyDefaultValues(filledRows, arrItem, myArrayPath)
              })
            }
          }
        }
      })
    }
  }
}
