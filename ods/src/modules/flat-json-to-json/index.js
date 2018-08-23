import _ from 'lodash'

const globalBatchKey = 'ODS_Batch_Id'
const globalBatchUNQKeyName = 'ODS_Id'
// const parent_key_refix = "ODS_Parent_Id_";
// const parent_table_name_key_prefix = "ODS_Parent_Table_";
const globalDefaultParentPath = 'ODS_Parent_Path'
const gloablDefaultParentUri = 'ODS_Parent_Uri'
const globalDefaultUri = 'ODS_Uri'
const globalDefaultUriPath = 'ODS_Path'
const globalBatchid = Math.floor(Math.random() * 100000)
let globalBatchUniqueId = 0

export function getNormalizedDataset(rowsArray, tableName, normalizedDataSet, debug = 0) {
  let parentKey
  const parentObject = null
  const rowsArrayWithIds = []

  // object has any items
  if (rowsArray && rowsArray.length > 0) {
    rowsArray.forEach((jsonRow) => {
      const jsonRowWithId = {}
      if (!_.isEmpty(jsonRow)) {
        const parentLevel = -1
        // PrintJson("input:json_row:", json_row, debug);
        IdMeAndMyDescendents(
          jsonRow,
          parentKey,
          parentLevel,
          tableName,
          tableName,
          parentObject,
          jsonRowWithId,
          debug
        )
        rowsArrayWithIds.push(_.cloneDeep(jsonRowWithId))
        PrintJson('json_row_with_id:', _.cloneDeep(jsonRowWithId), debug)
      }
    })
  }

  PrintJson('rows with IDs:', rowsArrayWithIds.length, debug)
  // object has any items
  if (rowsArrayWithIds && rowsArrayWithIds.length > 0) {
    rowsArrayWithIds.forEach((jsonRowWithId) => {
      if (!_.isEmpty(jsonRowWithId)) {
        normalizeMe(_.cloneDeep(jsonRowWithId), tableName, normalizedDataSet, debug)
      }
    })
  }
}

function IdMeAndMyDescendents(
  jsonRow,
  parentId,
  parentLevel,
  parentName,
  myName,
  parentObject,
  retJsonRow,
  debug = 0
) {
  // if no parent then we are the root.
  const myLevel = parentLevel + 1
  PrintMsg(`At Start: parent_level:${parentLevel} my_level: ${myLevel}`, debug)

  if (jsonRow && !_.isEmpty(jsonRow)) {
    // add ods details
    addBatchId(jsonRow)
    addBatchUniqueId(jsonRow, myName, debug)
    const myId = jsonRow[globalBatchUNQKeyName]

    // root - process default values for root. So recursion can take of the rest.
    if (IsRootObject(parentLevel, parentObject)) {
      // Add root representation for parent which would be simply a slash.
      // Parent value would be -1
      addDefaultParent(jsonRow)
    }

    // add parent if needed to given object.
    addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, jsonRow, debug)
    parentName = myName
    // check if it is a simple property/array/object
    const objAttributes = Object.keys(jsonRow)
    objAttributes.forEach((attribute) => {
      if (_.isArray(jsonRow[attribute])) {
        PrintMsg(
          `---- converting --array ----- parent: ${parentName} attribute: ${attribute}`,
          debug
        )
        if (IsArrayOfSimpleTypes(jsonRow[attribute])) {
          // let my_parent = getNewParentParamObject(my_id, my_name, my_level, json_row, debug);
          retJsonRow[attribute] = convertSimpleArrayToObjects(
            jsonRow[attribute],
            myId,
            myLevel,
            parentName,
            attribute,
            jsonRow,
            debug
          )
        } else {
          // loop through each object and get the values;
          const myObjArrays = jsonRow[attribute]
          // PrintJson("1.mapping my_obj_array:", my_obj_arrays);
          retJsonRow[attribute] = myObjArrays.map((val) => {
            // PrintJson("my_obj_array:", val, debug);
            PrintMsg(
              `2.parent:${myId} parent_my_level: ${myLevel} parent(attribute): ${attribute} parent: ${parentName}`,
              debug
            )
            const nObj = {}
            IdMeAndMyDescendents(val, myId, myLevel, parentName, attribute, jsonRow, nObj, debug)
            // PrintJson("9000.nObj:", nObj, debug);
            return nObj
          })
        }
        PrintMsg('---- converted --array -----', debug)
      } else if (jsonRow[attribute] instanceof Object) {
        const nObj = {}
        PrintJson('100.json_row:', jsonRow, debug)
        PrintMsg(
          `101.parent:${myId} parent_my_level: ${myLevel} parent(attribute): ${attribute} parent: ${parentName}`,
          debug
        )
        IdMeAndMyDescendents(
          jsonRow[attribute],
          myId,
          myLevel,
          parentName,
          attribute,
          jsonRow,
          nObj,
          debug
        )
        PrintJson('103.Child:', nObj, debug)
        retJsonRow[attribute] = nObj
      } else if (!(jsonRow[attribute] instanceof Object)) {
        // PrintJson("attribute:" + attribute + " value:", json_row[attribute], debug);
        retJsonRow[attribute] = jsonRow[attribute]
      }
    })

    // for (var attribute in jsonRow) {
    //   // above code using object keys was here.
    // }
  }
}

function IsRootObject(level, objectToCheck) {
  if (level === -1 && _.isUndefined(objectToCheck)) {
    return true
  }
  return false
}

function addDefaultParent(objectToAdd) {
  if (objectToAdd) {
    if (objectToAdd.default_parent_path) {
      objectToAdd[globalDefaultParentPath] = '/'
    }
  }
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
    // for (const attribute in objToTest) {
    //   // moved to above forEach due to ESLint complaining
    // }
  }
  return retVal
}

function convertSimpleArrayToObjects(
  arrayOfSimpleDataTypes,
  parentId,
  parentLevel,
  parentName,
  myName,
  parentObject,
  debug = 0
) {
  let retArray = []
  // is an array check
  if (arrayOfSimpleDataTypes instanceof Array) {
    // array has some elements
    if (arrayOfSimpleDataTypes.length > 0) {
      // only if array has simple object proceed or else we need to process it differently.
      // PrintJson("Array element value: ", array_of_simple_datatypes[0]);
      if (!_.isObject(arrayOfSimpleDataTypes[0])) {
        retArray = arrayOfSimpleDataTypes.map((val, idx) => {
          const obj = getNewObjectFromArrayElement(val, idx, myName, debug)
          PrintJson(`My parent at level: ${parentLevel} in array conversion:`, parentObject, debug)
          addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, obj, debug)
          PrintJson('Array after adding parent: ', obj, debug)
          return obj
        })
      } else {
        throw new Error('Array of objects in method that can process only array of simple types')
        // retArray = arrayOfSimpleDataTypes.map((val) => {
        //   throw new Error('Array of objects in method that can process only array of simple types');
        //   // const obj = addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, val, debug);
        //   // return obj;
        // });
      }
    }
  }
  return retArray
}

function addParentIdToChildObject(
  parentId,
  parentLevel,
  parentObject,
  parentName,
  childObj,
  debug = 0
) {
  if (parentLevel < 0) {
    parentLevel = 0
  }
  // let parent_key_name = parent_key_refix + parent_level;
  // let parent_table_name = parent_table_name_key_prefix + parent_level;

  PrintJson('Who am i:', childObj, debug)
  PrintJson('ParentId:', parentId, debug)
  PrintJson('Parent_level:', parentLevel, debug)
  PrintMsg(`parent_name:${parentName}`, debug)

  if (childObj && !_.isUndefined(parentId)) {
    // let parent_name_alias = parent_name + "." + batch_unique_key_name;
    // let parent_ods_path_alias = parent_name + "." + default_parent_path;

    // child_obj[parent_name_alias] = parent_id;
    childObj[globalDefaultParentPath] = `/${parentName}`
    childObj[gloablDefaultParentUri] = `/${parentId}`
    // child_obj[parent_key_name] = parent_id;
    // child_obj[parent_table_name] = parent_name;
    PrintJson(`after adding parent at level: ${parentLevel} to me :`, childObj, debug)
    if (parentObject && parentLevel > 0) {
      PrintMsg('adding my ancestors.', debug)
      // get all parent's parent_level_* props and add to me.
      // child_obj[parent_ods_path_alias] = parent_object[default_parent_path];
      childObj[globalDefaultParentPath] =
        parentObject[globalDefaultParentPath] + childObj[globalDefaultParentPath]
      childObj[gloablDefaultParentUri] =
        parentObject[gloablDefaultParentUri] + childObj[gloablDefaultParentUri]
    }
    updateUri(childObj, debug)
    // if (!child_obj.hasOwnProperty(parent_key_name)){}
  }
  PrintJson('Who am i after update:', childObj, debug)
}

function getNewObjectFromArrayElement(val, idx, arrayName, debug = 0) {
  const obj = {}
  obj.ArrayIndex = idx
  obj.ArrayValue = val
  addBatchId(obj)
  addBatchUniqueId(obj, arrayName, debug)
  PrintJson('obj', obj, debug)
  return obj
}

function getBatchUniqueId() {
  globalBatchUniqueId += 1
  return globalBatchUniqueId
}

function addBatchId(objToAdd) {
  if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
    if (!objToAdd[globalBatchKey]) {
      objToAdd[globalBatchKey] = globalBatchid
    }
  }
}

function addBatchUniqueId(objToAdd, objName, debug = 0) {
  if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
    if (!objToAdd[globalBatchUNQKeyName]) {
      objToAdd[globalBatchUNQKeyName] = getBatchUniqueId()
    }
    if (!objToAdd[globalDefaultUri]) {
      objToAdd[globalDefaultUri] = `/${objToAdd[globalBatchUNQKeyName]}`
    }
    addUriPath(objToAdd, objName)
    PrintJson('my keys added:', objToAdd, debug)
  }
}

function addUriPath(objToAdd, objName) {
  if (!_.isUndefined(objToAdd) && _.isObject(objToAdd)) {
    if (!objToAdd[globalDefaultUriPath]) {
      objToAdd[globalDefaultUriPath] = `/${objName}`
    }
  }
}

function updateUri(objToUpdate, debug = 0) {
  if (!_.isUndefined(objToUpdate) && _.isObject(objToUpdate)) {
    if (objToUpdate[globalDefaultUri]) {
      objToUpdate[globalDefaultUri] =
        objToUpdate[gloablDefaultParentUri] + objToUpdate[globalDefaultUri]
    }
    if (objToUpdate[globalDefaultUriPath]) {
      objToUpdate[globalDefaultUriPath] =
        objToUpdate[globalDefaultParentPath] + objToUpdate[globalDefaultUriPath]
    }
  }
  PrintJson('Uri updated', objToUpdate, debug)
}

function normalizeMe(jsonToNormalize, tableName, dataset, debug = 0) {
  const localCopy = jsonToNormalize
  PrintJson(`normalizeMe input: ${localCopy}`, debug)

  if (tableName.length > 0) {
    // create a new array
    if (!dataset[tableName]) {
      dataset[tableName] = []
    }
  }
  PrintMsg(`Table: ${tableName}`, debug)
  if (localCopy) {
    if (!_.isEmpty(localCopy)) {
      if (HasSimpleTypes(localCopy)) {
        const obj = {}
        // extract all properties of simple data types and add to our current table and return
        const AttributeKeys = Object.keys(localCopy)
        AttributeKeys.forEach((attribute) => {
          PrintMsg(`attribute: ${attribute}`, debug)
          PrintMsg(`type of: ${typeof localCopy[attribute]}`, debug)
          if (!(typeof localCopy[attribute] === 'object')) {
            obj[attribute] = localCopy[attribute]
            PrintJson(`Added: ${attribute} Value: ${localCopy[attribute]}`, debug)
            delete localCopy[attribute]
          }
        })
        // for (var attribute in localCopy) {
        //   // code in here was moved to above forEach due to ESLINT complaining
        // }
        // add to array
        dataset[tableName].push(obj)
      }

      const AttributeKeys = Object.keys(localCopy)
      AttributeKeys.forEach((attribute) => {
        if (_.isArray(localCopy[attribute])) {
          if (IsArrayOfSimpleTypes(localCopy[attribute])) {
            throw new Error('Objects that were cleaned shouldnt have simple arrays.')
          } else {
            // loop through each object and get the values;
            const myObjArrays = localCopy[attribute]
            PrintMsg(`processing elements of:${attribute}`, debug)
            PrintMsg(`# of elements to process: ${myObjArrays.length}`, debug)
            myObjArrays.forEach((val) => {
              // PrintJson("processing array element:", val, debug);
              normalizeMe(val, attribute, dataset)
              // return;
            })
            delete localCopy[attribute]
          }
        } else if (_.isObject(localCopy[attribute])) {
          PrintMsg(`processing attributes of object:${attribute}`, debug)
          normalizeMe(localCopy[attribute], attribute, dataset)
          delete localCopy[attribute]
        }
      })

      // for (var attribute in localCopy) {
      //   // code in here was moved to above forEach due to ESLint complaining
      // }
    }
  }
}

function PrintJson(caption, jsonToPrint, debug = 1) {
  if (debug === 1) {
    console.log(`${caption}: ${JSON.stringify(jsonToPrint, null, 2)}`)
  }
}

function PrintMsg(msg, debug = 0) {
  if (debug === 1) {
    console.log(msg)
  }
}
