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
    JsonKeysAndPath: {},
  }
  _jsonKeysAndParents = []
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
  get JsonKeysAndParent() {
    return this._jsonKeysAndParents
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
            this.LogString('Done adding IDs to objects.', 'debug')
            this.LogJson('json_row_with_id:', _.cloneDeep(jsonRowWithId), 'debug')
          }
        })
      }
      this.LogJson('rows with IDs:', rowsArrayWithIds.length, 'debug')
      // object has any items
      if (rowsArrayWithIds && rowsArrayWithIds.length > 0) {
        // add root table first
        this.JsonKeysAndParent.push({
          JsonKey: this.TableName,
          ParentKey: '',
          TableName: this.TableName,
        })
        rowsArrayWithIds.forEach((jsonRowWithId) => {
          if (!_.isEmpty(jsonRowWithId)) {
            this.GetKeysAndParents(jsonRowWithId, this.TableName)
            this.normalizeMe(_.cloneDeep(jsonRowWithId), this.TableName, '')
            this.LogString('Done normalizing data.', 'debug')
            // extract various tables and JSON schema paths for those tables.
            this.UpdateOuputAddKeysAndPath()
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
      this.LogString('Normalized Data is available.', 'debug')
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
        this.Output.NormalizedS3Path = await SaveJsonToS3File(this.Output.NormalizedDataSet, {
          S3OutputBucket: this.S3OutputBucket,
          S3OutputKey: this.S3OutputKey,
        })
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

  UpdateOuputAddKeysAndPath() {
    if (
      !_.isUndefined(this.Output.NormalizedDataSet) &&
      _.size(this.Output.NormalizedDataSet) > 0
    ) {
      // Loop through
      let idx = 0
      _.forIn(this.Output.NormalizedDataSet, (rows, tblName) => {
        let path = ''
        this.logger.log('debug', `table: ${tblName}, size: ${_.size(rows)}, idx: ${idx}`)
        if (!_.isEmpty(rows) && _.size(rows) > 0) {
          path = rows[0][this.globalDefaultUriPath] || '~Unknown'
          if (!_.isUndefined(path) && path.length > 0) {
            // only replace if there is a single Slash
            // if the slash is escaped then dont replace it.
            path = path.substring(1).replace(/([^\^]{1}[^~]{1})\//gi, '$1.')
          }
        }
        // extract ods_path
        this.Output.JsonKeysAndPath[`Flat.${idx}.JsonObjectName`] = tblName
        this.Output.JsonKeysAndPath[`Flat.${idx}.JsonSchemaPath`] = path
        idx += 1
      })
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
            // Add Array Index Id and Value ,so  ['test'] becomes => {Id:1, Value:'test'}
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
            retJsonRow[attribute] = myObjArrays.map((val) => {
              this.LogString(
                `2.parent:${myId} parent_my_level: ${myLevel} parent(attribute): ${attribute} parent: ${parentName}`,
                'debug'
              )
              const nObj = {}
              this.IdMeAndMyDescendents(val, myId, myLevel, parentName, attribute, jsonRow, nObj)
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
      childObj[this.globalDefaultParentPath] = `/${parentName.replace(/\//gi, '^~/')}`
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
    const obj = {
      ArrayIndex: idx,
      ArrayValue: val,
    }
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
        objToAdd[this.globalDefaultUriPath] = `/${objName.replace(/\//gi, '^~/')}`
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

  GetKeysAndParents(jsonRows, parent) {
    // add all keys of complex objects
    _.forEach(jsonRows, (value, key) => {
      if (_.isObject(jsonRows[key])) {
        // add only if the object is not already in our list
        if (
          !_.find(this.JsonKeysAndParent, function(o) {
            return o.JsonKey === key
          })
        ) {
          this.JsonKeysAndParent.push({
            JsonKey: key,
            ParentKey: parent,
            TableName: key,
          })
        } else if (
          !_.find(this.JsonKeysAndParent, function(o) {
            return o.JsonKey === key && o.ParentyKey === parent
          })
        ) {
          this.JsonKeysAndParent.push({
            JsonKey: key,
            ParentKey: parent,
            TableName: `${parent}_${key}`,
          })
        }
      }
    })

    _.forEach(jsonRows, (value, key) => {
      if (_.isArray(value)) {
        if (!IsArrayOfSimpleTypes(value)) {
          value.forEach((element) => {
            this.GetKeysAndParents(element, key)
          })
        }
      } else if (_.isObject(value)) {
        // add my children by doing a recursive call.
        this.GetKeysAndParents(value, key)
      }
    })
  }

  normalizeMe(jsonToNormalize, tableName, parentName) {
    const localCopy = jsonToNormalize
    this.LogString(`normalizeMe input: ${localCopy}`, 'debug')

    if (tableName.length > 0) {
      // create a new array
      // TODO: DATA-818 Fix: Each table should contain the Parent_Name
      // We can easily find PARENT NAME from the ODS_Path of this object.
      // let us do this only if Same object exists with different parent.
      this.initializeNormalizedDataSet(tableName, parentName)
    }
    this.LogString(`Table: ${tableName}`, 'debug')
    if (localCopy && !_.isEmpty(localCopy)) {
      // copy all simple objects
      this.copySimpleObject(tableName, localCopy, parentName)

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
              this.normalizeMe(val, attribute, tableName)
            })
            delete localCopy[attribute]
          }
        } else if (_.isObject(localCopy[attribute])) {
          this.LogString(`processing attributes of object:${attribute}`, 'debug')
          this.normalizeMe(localCopy[attribute], attribute, tableName)
          delete localCopy[attribute]
        }
      })

      // in case any properties left after processing complex objects.
      if (localCopy) this.copySimpleObject(tableName, localCopy, parentName)
    }
  }

  initializeNormalizedDataSet(jsonKey, parentKey) {
    // do we have the table already
    const tblNameObj = _.find(this.JsonKeysAndParent, function(o) {
      return o.JsonKey == jsonKey && o.ParentKey == parentKey
    })
    // if we dont have this table so far then simply add it
    if (tblNameObj && !this.Output.NormalizedDataSet[tblNameObj.TableName]) {
      this.Output.NormalizedDataSet[`${tblNameObj.TableName}`] = []
    } else if (!tblNameObj) {
      // This should never happen, if it does check
      // this.GetKeysAndParents is working properly.
      throw new Error(
        `Json Key: ${jsonKey} with Parent : ${parentKey} is not found in JsonKeysAndParents`
      )
    }
  }

  addToNormalizedDS(tableName, parentName, objToAdd) {
    const objKey = _.find(this.JsonKeysAndParent, (o) => {
      return o.JsonKey == tableName && o.ParentKey == parentName
    })
    if (objKey) {
      this.Output.NormalizedDataSet[objKey.TableName].push(objToAdd)
    } else {
      // This should never happen, if it does check
      // initializeNormalizedDataSet() & GetKeysAndParents() is working properly.
      throw new Error(
        `Table: ${tableName} with Parent : ${parentName} is not found in NormalizedDataSet`
      )
    }
  }

  copySimpleObject(tableName, sourceObject, parentName) {
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
        this.addToNormalizedDS(tableName, parentName, obj)
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
