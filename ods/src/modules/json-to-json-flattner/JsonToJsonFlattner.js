import _ from 'lodash'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { GetJSONFromS3Path, SaveJsonToS3File } from '../s3ODS/index'

export class JsonToJsonFlattner {
  globalBatchKey = 'ODS_Batch_Id'
  globalBatchUNQKeyName = 'ODS_Id'
  globalDefaultParentPath = 'ODS_Parent_Path'
  gloablDefaultParentUri = 'ODS_Parent_Uri'
  globalDefaultUri = 'ODS_Uri'
  globalDefaultUriPath = 'ODS_Path'
  globalBatchUniqueId = 0
  output = {
    status: {
      message: 'processing',
    },
    error: {},
    NormalizedDataSet: {},
    NormalizedS3Path: undefined,
  }
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
    this.s3DataFilePath = params.S3DataFilePath || ''
    this.s3OutputBucket = params.S3OutputBucket || ''
    this.s3OutputKey = params.S3OutputKey || ''
    this.tableName = params.TableName
    this.batchId = params.BatchId || Math.floor(Math.random() * 100000)
    this.loglevel = params.LogLevel || 'warn'
    this.inputFileHasData = false
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel
    this.logger.add(this.consoleTransport)
  }

  get S3DataFilePath() {
    return this.s3DataFilePath
  }
  get ModuleError() {
    return this.Output.error
  }
  get ModuleStatus() {
    return this.Output.status.message
  }
  get TableName() {
    return this.tableName
  }
  get Output() {
    return this.output
  }
  get BatchId() {
    return this.batchId
  }
  get S3OUtput() {
    return this.s3Output
  }
  get LogLevel() {
    return this.loglevel
  }
  get S3OutputBucket() {
    return this.s3OutputBucket
  }
  get S3OutputKey() {
    return this.s3OutputKey
  }
  get InputFileHasData() {
    return this.inputFileHasData
  }

  async getNormalizedDataset() {
    let parentKey
    const parentObject = null
    const rowsArrayWithIds = []

    try {
      this.ValidateParams()
      const rowsArray = await GetJSONFromS3Path(this.S3DataFilePath)
      // object has any items
      if (rowsArray && rowsArray.length > 0) {
        this.inputFileHasData = true
        rowsArray.forEach((jsonRow) => {
          const jsonRowWithId = {}
          if (!_.isEmpty(jsonRow)) {
            const parentLevel = -1
            // this.PrintJson("input:json_row:", json_row, 'debug');
            this.IdMeAndMyDescendents(
              jsonRow,
              parentKey,
              parentLevel,
              this.TableName,
              this.TableName,
              parentObject,
              jsonRowWithId
            )
            rowsArrayWithIds.push(_.cloneDeep(jsonRowWithId))
            this.LogString('Done adding IDs to objects.', 'info')
            this.LogJson('json_row_with_id:', _.cloneDeep(jsonRowWithId), 'debug')
          }
        })
      }
      this.LogJson('rows with IDs:', rowsArrayWithIds.length, 'debug')
      // object has any items
      if (rowsArrayWithIds && rowsArrayWithIds.length > 0) {
        rowsArrayWithIds.forEach((jsonRowWithId) => {
          if (!_.isEmpty(jsonRowWithId)) {
            this.normalizeMe(_.cloneDeep(jsonRowWithId), this.TableName)
            this.LogString('Done normalizing data.', 'info')
          }
        })
      } else if (this.InputFileHasData) {
        throw new Error(
          `No data to Normalize. Length of Rows with Arrays and IDs: ${rowsArrayWithIds.length}`
        )
      }
      this.Output.status.message = 'success'
    } catch (err) {
      this.Output.status.message = 'error'
      this.Output.NormalizedDataSet = undefined
      this.Output.error = new Error(`Error normalizing data: ${err.message}`)
      this.logger.log('error', `Error: ${err.message}`)
      throw this.Output.error
    }
  }

  async SaveNormalizedData() {
    try {
      // get normalized data
      await this.getNormalizedDataset()
      this.LogString('Normalized Data is available.', 'info')
      if (
        this.ModuleStatus !== 'success' ||
        !this.Output.NormalizedDataSet ||
        Object.keys(this.Output.NormalizedDataSet).length <= 0
      ) {
        const msg = this.Output.error
          ? this.Output.error.message
          : `Length of Normalized DataSet:${Object.keys(this.Output.NormalizedDataSet).length}`
        throw new Error(`Normalized data Set is empty, nothing to save. ${msg}`)
      }
    } catch (err) {
      this.Output.status.message = 'error'
      this.Output.error = new Error(`Error getting Normalized Data: ${err.message}`)
      this.logger.log('error', JSON.stringify(this.Output.error.message))
      return
    }
    // if no issue getting data then proceed.
    try {
      this.Output.status.message = 'SavingToS3'
      // validate bucket info and proceed.
      if (
        this.S3OutputBucket &&
        this.S3OutputKey &&
        this.S3OutputBucket.length > 0 &&
        this.S3OutputKey.length > 0
      ) {
        this.LogString('About to Save S3 file.', 'info')
        this.Output.NormalizedS3Path = await SaveJsonToS3File(
          `s3://${this.S3OutputBucket}/${this.S3OutputKey}`,
          this.Output.NormalizedDataSet
        )
        this.LogString('Done saving file to S3.', 'info')
        this.Output.status.message = 'success'
        this.error = undefined
        this.Output.NormalizedDataSet = undefined
      } else {
        throw new Error(
          `S3Bucket and S3Key are required to save data. S3Bucket:${
            this.S3OutputBucket
          }, S3Key Value: ${this.S3OutputKey}`
        )
      }
    } catch (err) {
      this.Output.status.message = 'error'
      this.Output.error = new Error(`Error saving file to S3: ${err.message}`)
      this.logger.log('error', JSON.stringify(this.Output.error.message))
      throw this.Output.error
    }
  }

  IdMeAndMyDescendents(
    jsonRow,
    parentId,
    parentLevel,
    parentName,
    myName,
    parentObject,
    retJsonRow
  ) {
    // if no parent then we are the root.
    const myLevel = parentLevel + 1
    this.LogString(`At Start: parent_level:${parentLevel} my_level: ${myLevel}`, 'debug')

    if (jsonRow && !_.isEmpty(jsonRow)) {
      // add ods details
      this.addBatchId(jsonRow)
      this.addBatchUniqueId(jsonRow, myName)
      const myId = jsonRow[this.globalBatchUNQKeyName]

      // root - process default values for root. So recursion can take of the rest.
      if (IsRootObject(parentLevel, parentObject)) {
        // Add root representation for parent which would be simply a slash.
        // Parent value would be -1
        this.addDefaultParent(jsonRow)
      }

      // add parent if needed to given object.
      this.addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, jsonRow)
      parentName = myName
      // check if it is a simple property/array/object
      const objAttributes = Object.keys(jsonRow)
      objAttributes.forEach((attribute) => {
        if (_.isArray(jsonRow[attribute])) {
          this.LogString(
            `---- converting --array ----- parent: ${parentName} attribute: ${attribute}`,
            'debug'
          )
          if (IsArrayOfSimpleTypes(jsonRow[attribute])) {
            // let my_parent = getNewParentParamObject(my_id, my_name, my_level, json_row);
            retJsonRow[attribute] = this.convertSimpleArrayToObjects(
              jsonRow[attribute],
              myId,
              myLevel,
              parentName,
              attribute,
              jsonRow
            )
          } else {
            // loop through each object and get the values;
            const myObjArrays = jsonRow[attribute]
            // this.PrintJson("1.mapping my_obj_array:", my_obj_arrays, 'debug');
            retJsonRow[attribute] = myObjArrays.map((val) => {
              // this.PrintJson("my_obj_array:", val, 'debug');
              this.LogString(
                `2.parent:${myId} parent_my_level: ${myLevel} parent(attribute): ${attribute} parent: ${parentName}`,
                'debug'
              )
              const nObj = {}
              this.IdMeAndMyDescendents(val, myId, myLevel, parentName, attribute, jsonRow, nObj)
              // this.PrintJson("9000.nObj:", nObj, 'debug');
              return nObj
            })
          }
          this.LogString('---- converted --array -----', 'debug')
        } else if (_.isObject(jsonRow[attribute])) {
          const nObj = {}
          this.LogJson('100.json_row:', jsonRow, 'debug')
          this.LogString(
            `101.parent:${myId} parent_my_level: ${myLevel} parent(attribute): ${attribute} parent: ${parentName}`,
            'debug'
          )
          this.IdMeAndMyDescendents(
            jsonRow[attribute],
            myId,
            myLevel,
            parentName,
            attribute,
            jsonRow,
            nObj
          )
          this.LogJson('103.Child:', nObj, 'debug')
          retJsonRow[attribute] = nObj
        } else if (!(jsonRow[attribute] instanceof Object)) {
          retJsonRow[attribute] = jsonRow[attribute]
        }
      })
    }
  }

  convertSimpleArrayToObjects(
    arrayOfSimpleDataTypes,
    parentId,
    parentLevel,
    parentName,
    myName,
    parentObject
  ) {
    let retArray = []
    // is an array check
    if (arrayOfSimpleDataTypes instanceof Array) {
      // array has some elements
      if (arrayOfSimpleDataTypes.length > 0) {
        // only if array has simple object proceed or else we need to process it differently.
        if (!_.isObject(arrayOfSimpleDataTypes[0])) {
          retArray = arrayOfSimpleDataTypes.map((val, idx) => {
            const obj = this.getNewObjectFromArrayElement(val, idx, myName)
            this.LogJson(
              `My parent at level: ${parentLevel} in array conversion:`,
              parentObject,
              'debug'
            )
            this.addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, obj)
            this.LogJson('Array after adding parent: ', obj, 'debug')
            return obj
          })
        } else {
          throw new Error('Array of objects in method that can process only array of simple types')
        }
      }
    }
    return retArray
  }

  ValidateParams() {
    if (_.isEmpty(this.TableName)) {
      throw new Error('Invalid Param. Please pass a TableName')
    }
    if (_.isEmpty(this.S3DataFilePath)) {
      throw new Error('Invalid Param. Please pass valid S3 File')
    }
  }

  addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, childObj) {
    if (parentLevel < 0) {
      parentLevel = 0
    }

    this.LogJson('Who am i:', childObj, 'debug')
    this.LogString(
      `ParentId: ${parentId} Parent_level: ${parentLevel} parent_name: ${parentName}`,
      'debug'
    )

    if (childObj && !_.isUndefined(parentId)) {
      childObj[this.globalDefaultParentPath] = `/${parentName}`
      childObj[this.gloablDefaultParentUri] = `/${parentId}`

      this.LogJson(`after adding parent at level: ${parentLevel} to me :`, childObj, 'debug')
      if (parentObject && parentLevel > 0) {
        this.LogString('adding my ancestors.', 'debug')
        // get all parent's parent_level_* props and add to me.
        childObj[this.globalDefaultParentPath] =
          parentObject[this.globalDefaultParentPath] + childObj[this.globalDefaultParentPath]
        childObj[this.gloablDefaultParentUri] =
          parentObject[this.gloablDefaultParentUri] + childObj[this.gloablDefaultParentUri]
      }
      this.updateUri(childObj)
    }
    this.LogJson('Who am i after update:', childObj, 'debug')
  }

  getNewObjectFromArrayElement(val, idx, arrayName) {
    const obj = {}
    obj.ArrayIndex = idx
    obj.ArrayValue = val
    this.addBatchId(obj)
    this.addBatchUniqueId(obj, arrayName)
    this.LogJson('obj', obj, 'debug')
    return obj
  }

  getBatchUniqueId() {
    this.globalBatchUniqueId += 1
    return this.globalBatchUniqueId
  }

  addBatchId(objToAdd) {
    if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
      if (!objToAdd[this.globalBatchKey]) {
        objToAdd[this.globalBatchKey] = this.BatchId
      }
    }
  }

  addBatchUniqueId(objToAdd, objName) {
    if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
      if (!objToAdd[this.globalBatchUNQKeyName]) {
        objToAdd[this.globalBatchUNQKeyName] = this.getBatchUniqueId()
      }
      if (!objToAdd[this.globalDefaultUri]) {
        objToAdd[this.globalDefaultUri] = `/${objToAdd[this.globalBatchUNQKeyName]}`
      }
      this.addUriPath(objToAdd, objName)
      this.LogJson('my keys added:', objToAdd, 'debug')
    }
  }

  addUriPath(objToAdd, objName) {
    if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
      if (!objToAdd[this.globalDefaultUriPath]) {
        objToAdd[this.globalDefaultUriPath] = `/${objName}`
      }
    }
  }

  updateUri(objToUpdate) {
    if (!_.isUndefined(objToUpdate) && _.isObject(objToUpdate)) {
      if (objToUpdate[this.globalDefaultUri]) {
        objToUpdate[this.globalDefaultUri] =
          objToUpdate[this.gloablDefaultParentUri] + objToUpdate[this.globalDefaultUri]
      }
      if (objToUpdate[this.globalDefaultUriPath]) {
        objToUpdate[this.globalDefaultUriPath] =
          objToUpdate[this.globalDefaultParentPath] + objToUpdate[this.globalDefaultUriPath]
      }
    }
    this.LogJson('Uri updated', objToUpdate, 'debug')
  }

  normalizeMe(jsonToNormalize, tableName) {
    const localCopy = jsonToNormalize
    this.LogString(`normalizeMe input: ${localCopy}`, 'debug')

    if (tableName.length > 0) {
      // create a new array
      if (!this.Output.NormalizedDataSet[tableName]) {
        this.Output.NormalizedDataSet[tableName] = []
      }
    }
    this.LogString(`Table: ${tableName}`, 'debug')
    if (localCopy && !_.isEmpty(localCopy)) {
      // copy all simple objects
      this.copySimpleObject(tableName, localCopy)

      const AttributeKeys = Object.keys(localCopy)
      AttributeKeys.forEach((attribute) => {
        if (_.isArray(localCopy[attribute])) {
          if (IsArrayOfSimpleTypes(localCopy[attribute])) {
            throw new Error('Objects that were cleaned shouldnt have simple arrays.')
          } else {
            // loop through each object and normalize each of them;
            const myObjArrays = localCopy[attribute]
            this.LogString(
              `processing elements of:${attribute} # of elements to process: ${myObjArrays.length}`,
              'debug'
            )
            myObjArrays.forEach((val) => {
              this.normalizeMe(val, attribute)
            })
            delete localCopy[attribute]
          }
        } else if (_.isObject(localCopy[attribute])) {
          this.LogString(`processing attributes of object:${attribute}`, 'debug')
          this.normalizeMe(localCopy[attribute], attribute)
          delete localCopy[attribute]
        }
      })

      // in case any properties left after processing complex objects.
      if (localCopy) this.copySimpleObject(tableName, localCopy)
    }
  }

  copySimpleObject(tableName, sourceObject) {
    if (HasSimpleTypes(sourceObject)) {
      const obj = {}
      // extract all properties of simple data types and add to our current table and return
      const AttributeKeys = Object.keys(sourceObject)
      AttributeKeys.forEach((attribute) => {
        this.LogString(
          `attribute: ${attribute} type of: ${typeof sourceObject[attribute]}`,
          'debug'
        )
        if (!_.isObject(sourceObject[attribute])) {
          obj[attribute] = sourceObject[attribute]
          this.LogString(`Added: ${attribute} Value: ${sourceObject[attribute]}`, 'debug')
          delete sourceObject[attribute]
        }
      })

      // add to array
      if (AttributeKeys && AttributeKeys.length > 0) {
        this.Output.NormalizedDataSet[tableName].push(obj)
      }
    }
  }

  addDefaultParent(objectToAdd) {
    if (objectToAdd) {
      if (objectToAdd.default_parent_path) {
        objectToAdd[this.globalDefaultParentPath] = '/'
      }
    }
  }

  LogJson(caption, jsonToPrint, loglevel = 'warn') {
    this.logger.log(
      loglevel || this.LogLevel,
      `${caption}: ${JSON.stringify(jsonToPrint, null, 2)}`
    )
  }

  LogString(msg, loglevel = 'warn') {
    this.logger.log(loglevel || this.LogLevel, msg)
  }
}

function IsRootObject(level, objectToCheck) {
  if (level === -1 && _.isUndefined(objectToCheck)) {
    return true
  }
  return false
}

function IsArrayOfSimpleTypes(arrayToTest) {
  let retval = false
  if (arrayToTest.length > 0) {
    let hasObject = false
    hasObject = arrayToTest.some((val) => val instanceof Object)
    retval = !hasObject
  }
  return retval
}

function HasSimpleTypes(objToTest) {
  let retVal = false
  let intCnt = 0
  if (objToTest) {
    const objAttributes = Object.keys(objToTest)
    objAttributes.forEach((attribute) => {
      if (!(objToTest[attribute] instanceof Array || objToTest[attribute] instanceof Object)) {
        intCnt += 1
      }
    })
    retVal = intCnt === objAttributes.length
  }
  return retVal
}
