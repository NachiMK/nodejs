import _ from 'lodash';
import { format as _format, transports as _transports, createLogger } from 'winston';
import { GetJSONFromS3Path } from '../s3ODS/index';

export class JsonToJsonFlattner {
    globalBatchKey = 'ODS_Batch_Id';
    globalBatchUNQKeyName = 'ODS_Id';
    globalDefaultParentPath = 'ODS_Parent_Path';
    gloablDefaultParentUri = 'ODS_Parent_Uri';
    globalDefaultUri = 'ODS_Uri';
    globalDefaultUriPath = 'ODS_Path';
    globalBatchUniqueId = 0;
    output = {
      Status: 'processing',
      error: {},
      NormalizedDataSet: {},
      NormalizedFilePaths: {},
    };
    logger = createLogger({
      format: _format.combine(
        _format.timestamp({
          format: 'YYYY-MM-DD HH:mm:ss',
        }),
        _format.splat(),
        _format.prettyPrint(),
      ),
      transports: [
        new (_transports.Console)({
          level: 'error',
        }),
      ],
    });

    constructor(params = {}) {
      this.s3DataFilePath = params.S3DataFilePath || '';
      this.s3Output = params.S3Output || '';
      this.tableName = params.TableName;
      this.outputType = params.OutputType || 'Return-in-output'; // Can be Save-to-S3 or Return-in-output
      this.batchId = params.BatchId || Math.floor(Math.random() * 100000);
      if (!this.S3Output || (this.S3Output.length <= 0)) this.outputType = 'Return-in-output';
      this.loglevel = params.LogLevel || 'warn';
    }

    get S3DataFilePath() {
      return this.s3DataFilePath;
    }
    get ModuleError() {
      return this.Output.error;
    }
    get ModuleStatus() {
      return this.Output.Status;
    }
    get TableName() {
      return this.tableName;
    }
    get Output() {
      return this.output;
    }
    get OutputType() {
      return this.outputType;
    }
    get BatchId() {
      return this.batchId;
    }
    get S3OUtput() {
      return this.s3Output;
    }
    get LogLevel() {
      return this.loglevel;
    }

    async getNormalizedDataset() {
      let parentKey;
      const parentObject = null;
      const rowsArrayWithIds = [];

      try {
        this.ValidateParams();
        const rowsArray = await GetJSONFromS3Path(this.S3DataFilePath);
        // object has any items
        if (rowsArray && rowsArray.length > 0) {
          rowsArray.forEach((jsonRow) => {
            const jsonRowWithId = {};
            if (!(_.isEmpty(jsonRow))) {
              const parentLevel = -1;
              // this.PrintJson("input:json_row:", json_row);
              this.IdMeAndMyDescendents(jsonRow, parentKey, parentLevel, this.TableName, this.TableName, parentObject, jsonRowWithId);
              rowsArrayWithIds.push(_.cloneDeep(jsonRowWithId));
              this.LogJson('json_row_with_id:', _.cloneDeep(jsonRowWithId));
            }
          });
        }
        this.LogJson('rows with IDs:', rowsArrayWithIds.length);
        // object has any items
        if (rowsArrayWithIds && (rowsArrayWithIds.length > 0)) {
          rowsArrayWithIds.forEach((jsonRowWithId) => {
            if (!(_.isEmpty(jsonRowWithId))) {
              this.normalizeMe(_.cloneDeep(jsonRowWithId), this.TableName);
            }
          });
        }
        this.Output.Status = 'success';
      } catch (err) {
        this.Output.Status = 'error';
        this.Output.error = new Error(`Error normalizing data: ${err.message}`);
        console.log(`Error: ${err.message}`);
      }
    }

    IdMeAndMyDescendents(jsonRow, parentId, parentLevel, parentName, myName, parentObject, retJsonRow) {
      // if no parent then we are the root.
      const myLevel = parentLevel + 1;
      this.LogString(`At Start: parent_level:${parentLevel} my_level: ${myLevel}`);

      if (jsonRow && !(_.isEmpty(jsonRow))) {
        // add ods details
        this.addBatchId(jsonRow);
        this.addBatchUniqueId(jsonRow, myName);
        const myId = jsonRow[this.globalBatchUNQKeyName];

        // root - process default values for root. So recursion can take of the rest.
        if (IsRootObject(parentLevel, parentObject)) {
          // Add root representation for parent which would be simply a slash.
          // Parent value would be -1
          this.addDefaultParent(jsonRow);
        }

        // add parent if needed to given object.
        this.addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, jsonRow);
        parentName = myName;
        // check if it is a simple property/array/object
        const objAttributes = Object.keys(jsonRow);
        objAttributes.forEach((attribute) => {
          if (_.isArray(jsonRow[attribute])) {
            this.LogString(`---- converting --array ----- parent: ${parentName} attribute: ${attribute}`);
            if (IsArrayOfSimpleTypes(jsonRow[attribute])) {
              // let my_parent = getNewParentParamObject(my_id, my_name, my_level, json_row);
              retJsonRow[attribute] = this.convertSimpleArrayToObjects(jsonRow[attribute], myId, myLevel, parentName, attribute, jsonRow);
            } else {
              // loop through each object and get the values;
              const myObjArrays = jsonRow[attribute];
              // this.PrintJson("1.mapping my_obj_array:", my_obj_arrays);
              retJsonRow[attribute] = myObjArrays.map((val) => {
                // this.PrintJson("my_obj_array:", val);
                this.LogString(`2.parent:${myId} parent_my_level: ${myLevel} parent(attribute): ${attribute} parent: ${parentName}`);
                const nObj = {};
                this.IdMeAndMyDescendents(val, myId, myLevel, parentName, attribute, jsonRow, nObj);
                // this.PrintJson("9000.nObj:", nObj);
                return nObj;
              });
            }
            this.LogString('---- converted --array -----');
          } else if (jsonRow[attribute] instanceof Object) {
            const nObj = {};
            this.LogJson('100.json_row:', jsonRow);
            this.LogString(`101.parent:${myId} parent_my_level: ${myLevel} parent(attribute): ${attribute} parent: ${parentName}`);
            this.IdMeAndMyDescendents(jsonRow[attribute], myId, myLevel, parentName, attribute, jsonRow, nObj);
            this.LogJson('103.Child:', nObj);
            retJsonRow[attribute] = nObj;
          } else if (!(jsonRow[attribute] instanceof Object)) {
            // this.PrintJson("attribute:" + attribute + " value:", json_row[attribute]);
            retJsonRow[attribute] = jsonRow[attribute];
          }
        });

        // for (var attribute in jsonRow) {
        //   // above code using object keys was here.
        // }
      }
    }

    convertSimpleArrayToObjects(arrayOfSimpleDataTypes, parentId, parentLevel, parentName, myName, parentObject) {
      let retArray = [];
      // is an array check
      if (arrayOfSimpleDataTypes instanceof Array) {
        // array has some elements
        if (arrayOfSimpleDataTypes.length > 0) {
          // only if array has simple object proceed or else we need to process it differently.
          // this.PrintJson("Array element value: ", array_of_simple_datatypes[0]);
          if (!(_.isObject(arrayOfSimpleDataTypes[0]))) {
            retArray = arrayOfSimpleDataTypes.map((val, idx) => {
              const obj = this.getNewObjectFromArrayElement(val, idx, myName);
              this.LogJson(`My parent at level: ${parentLevel} in array conversion:`, parentObject);
              this.addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, obj);
              this.LogJson('Array after adding parent: ', obj);
              return obj;
            });
          } else {
            throw new Error('Array of objects in method that can process only array of simple types');
            // retArray = arrayOfSimpleDataTypes.map((val) => {
            //   throw new Error('Array of objects in method that can process only array of simple types');
            //   // const obj = addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, val);
            //   // return obj;
            // });
          }
        }
      }
      return retArray;
    }

    ValidateParams() {
      if (_.isEmpty(this.TableName)) {
        throw new Error('Invalid Param. Please pass a TableName');
      }
      if (_.isEmpty(this.S3DataFilePath)) {
        throw new Error('Invalid Param. Please pass valid S3 File');
      }
    }

    addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, childObj) {
      if (parentLevel < 0) {
        parentLevel = 0;
      }
      // let parent_key_name = parent_key_refix + parent_level;
      // let parent_table_name = parent_table_name_key_prefix + parent_level;

      this.LogJson('Who am i:', childObj);
      this.LogJson('ParentId:', parentId);
      this.LogJson('Parent_level:', parentLevel);
      this.LogString(`parent_name:${parentName}`);

      if ((childObj) && (!_.isUndefined(parentId))) {
        // let parent_name_alias = parent_name + "." + batch_unique_key_name;
        // let parent_ods_path_alias = parent_name + "." + default_parent_path;

        // child_obj[parent_name_alias] = parent_id;
        childObj[this.globalDefaultParentPath] = `/${parentName}`;
        childObj[this.gloablDefaultParentUri] = `/${parentId}`;
        // child_obj[parent_key_name] = parent_id;
        // child_obj[parent_table_name] = parent_name;
        this.LogJson(`after adding parent at level: ${parentLevel} to me :`, childObj);
        if ((parentObject) && (parentLevel > 0)) {
          this.LogString('adding my ancestors.');
          // get all parent's parent_level_* props and add to me.
          // child_obj[parent_ods_path_alias] = parent_object[default_parent_path];
          childObj[this.globalDefaultParentPath] = parentObject[this.globalDefaultParentPath] + childObj[this.globalDefaultParentPath];
          childObj[this.gloablDefaultParentUri] = parentObject[this.gloablDefaultParentUri] + childObj[this.gloablDefaultParentUri];
        }
        this.updateUri(childObj);
        // if (!child_obj.hasOwnProperty(parent_key_name)){}
      }
      this.LogJson('Who am i after update:', childObj);
    }

    getNewObjectFromArrayElement(val, idx, arrayName) {
      const obj = {};
      obj.ArrayIndex = idx;
      obj.ArrayValue = val;
      this.addBatchId(obj);
      this.addBatchUniqueId(obj, arrayName);
      this.LogJson('obj', obj);
      return obj;
    }

    getBatchUniqueId() {
      this.globalBatchUniqueId += 1;
      return this.globalBatchUniqueId;
    }

    addBatchId(objToAdd) {
      if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
        if (!objToAdd[this.globalBatchKey]) {
          objToAdd[this.globalBatchKey] = this.BatchId;
        }
      }
    }

    addBatchUniqueId(objToAdd, objName) {
      if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
        if (!objToAdd[this.globalBatchUNQKeyName]) {
          objToAdd[this.globalBatchUNQKeyName] = this.getBatchUniqueId();
        }
        if (!objToAdd[this.globalDefaultUri]) {
          objToAdd[this.globalDefaultUri] = `/${objToAdd[this.globalBatchUNQKeyName]}`;
        }
        this.addUriPath(objToAdd, objName);
        this.LogJson('my keys added:', objToAdd);
      }
    }

    addUriPath(objToAdd, objName) {
      if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
        if (!objToAdd[this.globalDefaultUriPath]) {
          objToAdd[this.globalDefaultUriPath] = `/${objName}`;
        }
      }
    }

    updateUri(objToUpdate) {
      if (!_.isUndefined(objToUpdate) && _.isObject(objToUpdate)) {
        if (objToUpdate[this.globalDefaultUri]) {
          objToUpdate[this.globalDefaultUri] = objToUpdate[this.gloablDefaultParentUri] + objToUpdate[this.globalDefaultUri];
        }
        if (objToUpdate[this.globalDefaultUriPath]) {
          objToUpdate[this.globalDefaultUriPath] = objToUpdate[this.globalDefaultParentPath] + objToUpdate[this.globalDefaultUriPath];
        }
      }
      this.LogJson('Uri updated', objToUpdate);
    }


    normalizeMe(jsonToNormalize, tableName) {
      const localCopy = jsonToNormalize;
      this.LogJson(`normalizeMe input: ${localCopy}`);

      if (tableName.length > 0) {
        // create a new array
        if (!(this.Output.NormalizedDataSet[tableName])) {
          this.Output.NormalizedDataSet[tableName] = [];
        }
      }
      this.LogString(`Table: ${tableName}`);
      if (localCopy && !(_.isEmpty(localCopy))) {
        // if (HasSimpleTypes(localCopy)) {
        //   const obj = {};
        //   // extract all properties of simple data types and add to our current table and return
        //   const AttributeKeys = Object.keys(localCopy);
        //   AttributeKeys.forEach((attribute) => {
        //     this.LogString(`attribute: ${attribute}`);
        //     this.LogString(`type of: ${typeof (localCopy[attribute])}`);
        //     if (!(typeof (localCopy[attribute]) === 'object')) {
        //       obj[attribute] = localCopy[attribute];
        //       this.LogJson(`Added: ${attribute} Value: ${localCopy[attribute]}`);
        //       delete localCopy[attribute];
        //     }
        //   });
        //   // for (var attribute in localCopy) {
        //   //   // code in here was moved to above forEach due to ESLINT complaining
        //   // }
        //   // add to array
        //   this.Output.NormalizedDataSet[tableName].push(obj);
        // }
        this.copySimpleProperties(tableName, localCopy);

        const AttributeKeys = Object.keys(localCopy);
        AttributeKeys.forEach((attribute) => {
          if (_.isArray(localCopy[attribute])) {
            if (IsArrayOfSimpleTypes(localCopy[attribute])) {
              throw new Error('Objects that were cleaned shouldnt have simple arrays.');
            } else {
              // loop through each object and get the values;
              const myObjArrays = localCopy[attribute];
              this.LogString(`processing elements of:${attribute}`);
              this.LogString(`# of elements to process: ${myObjArrays.length}`);
              myObjArrays.forEach((val) => {
                // this.PrintJson("processing array element:", val);
                this.normalizeMe(val, attribute);
                // return;
              });
              delete localCopy[attribute];
            }
          } else if (_.isObject(localCopy[attribute])) {
            this.LogString(`processing attributes of object:${attribute}`);
            this.normalizeMe(localCopy[attribute], attribute);
            delete localCopy[attribute];
          }
        });

        this.copySimpleProperties(tableName, localCopy);

        // for (var attribute in localCopy) {
        //   // code in here was moved to above forEach due to ESLint complaining
        // }
      }
    }

    copySimpleProperties(tableName, sourceObject) {
      if (HasSimpleTypes(sourceObject)) {
        const obj = {};
        // extract all properties of simple data types and add to our current table and return
        const AttributeKeys = Object.keys(sourceObject);
        AttributeKeys.forEach((attribute) => {
          this.LogString(`attribute: ${attribute} type of: ${typeof (sourceObject[attribute])}`);
          if (!_.isObject(sourceObject[attribute])) {
            obj[attribute] = sourceObject[attribute];
            this.LogJson(`Added: ${attribute} Value: ${sourceObject[attribute]}`);
            delete sourceObject[attribute];
          }
        });
        // for (var attribute in localCopy) {
        //   // code in here was moved to above forEach due to ESLINT complaining
        // }
        // add to array
        this.Output.NormalizedDataSet[tableName].push(obj);
      }
    }

    addDefaultParent(objectToAdd) {
      if (objectToAdd) {
        if (objectToAdd.default_parent_path) {
          objectToAdd[this.globalDefaultParentPath] = '/';
        }
      }
    }

    LogJson(caption, jsonToPrint) {
      this.logger.log(this.LogLevel, `${caption}: ${JSON.stringify(jsonToPrint, null, 2)}`);
    }

    LogString(msg) {
      this.logger.log(this.LogLevel, msg);
    }
}

function IsRootObject(level, objectToCheck) {
  if ((level === -1) && (_.isUndefined(objectToCheck))) {
    return true;
  }
  return false;
}

function IsArrayOfSimpleTypes(arrayToTest) {
  let retval = false;
  if (arrayToTest.length > 0) {
    let hasObject = false;
    hasObject = arrayToTest.some(val => val instanceof Object);
    retval = !hasObject;
  }
  return retval;
}

function HasSimpleTypes(objToTest) {
  let retVal = false;
  let intCnt = 0;
  if (objToTest) {
    const objAttributes = Object.keys(objToTest);
    objAttributes.forEach((attribute) => {
      if (!((objToTest[attribute] instanceof Array) || (objToTest[attribute] instanceof Object))) {
        intCnt += 1;
      }
    });
    retVal = (intCnt === objAttributes.length);
    // for (const attribute in objToTest) {
    //   // moved to above forEach due to ESLint complaining 
    // }
  }
  return retVal;
}
