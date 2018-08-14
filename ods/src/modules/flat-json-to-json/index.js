import _ from 'lodash';

const batch_key = 'ODS_Batch_Id';
const batch_unique_key_name = 'ODS_Id';
// const parent_key_refix = "ODS_Parent_Id_";
// const parent_table_name_key_prefix = "ODS_Parent_Table_";
const default_parent_path = 'ODS_Parent_Path';
const default_parent_Uri = 'ODS_Parent_Uri';
const default_Uri = 'ODS_Uri';
const default_Uri_Path = 'ODS_Path';
const batch_unique_id = 0;

export function getNormalizedDataset(rowsArray, tableName, normalizedDataSet, debug = 0) {
  let parentKey;
  const parentObject = null;
  const rowsArrayWithIds = [];

  if (rowsArray) {
    // object has any items
    if (rowsArray.length > 0) {
      rowsArray.forEach((jsonRow) => {
        const jsonRowWithId = {};
        if (!(_.isEmpty(jsonRow))) {
          const parentLevel = -1;
          // print_json("input:json_row:", json_row, debug);
          IdMeAndMyDescendents(jsonRow, parentKey, parentLevel, tableName, tableName, parentObject, jsonRowWithId, debug);
          rowsArrayWithIds.push(_.cloneDeep(jsonRowWithId));
          PrintJson('json_row_with_id:', _.cloneDeep(jsonRowWithId), debug);
        }
      });
    }
  }
  PrintJson('rows with IDs:', rowsArrayWithIds.length, debug);

  if (rowsArrayWithIds) {
    // object has any items
    if (rowsArrayWithIds.length > 0) {
      rowsArrayWithIds.forEach((jsonRowWithId) => {
        if (!(_.isEmpty(jsonRowWithId))) {
          normalizeMe(_.cloneDeep(jsonRowWithId), tableName, normalizedDataSet, debug);
        }
      });
    }
  }
}

function IdMeAndMyDescendents(jsonRow, parentId, parentLevel, parentName, myName, parentObject, retJsonRow, debug = 0) {

  // if no parent then we are the root.
  const myLevel = parentLevel + 1;
  PrintMsg(`At Start: parent_level:${parentLevel} my_level: ${myLevel}`, debug);

  if (jsonRow) {
    if (!(_.isEmpty(jsonRow))) {
      // add ods details
      addBatchId(jsonRow);
      addBatchUniqueId(jsonRow, myName, debug);
      const myId = jsonRow[batch_unique_key_name];

      // root - process default values for root. So recursion can take of the rest.
      if (IsRootObject(parentLevel, parentObject)) {
        // Add root representation for parent which would be simply a slash.
        // Parent value would be -1
        addDefaultParent(jsonRow);
      }

      // add parent if needed to given object.
      addParentIdToChildObject(parentId, parentLevel, parentObject, parentName, jsonRow, debug);
      parentName = myName;
      // check if it is a simple property/array/object
      const objAttributes = Object.keys(jsonRow);
      objAttributes.forEach((attribute) => {

      });

      for (var attribute in jsonRow) {
        if (jsonRow[attribute] instanceof Array) {
          print_msg(`---- converting --array ----- parent: ${parentName} attribute: ${attribute}`, debug);
          if (IsArrayOfSimpleTypes(jsonRow[attribute])) {
            // let my_parent = getNewParentParamObject(my_id, my_name, my_level, json_row, debug);
            retJsonRow[attribute] = convertSimpleArrayToObjects(jsonRow[attribute], myId, myLevel, parentName, attribute, jsonRow, debug);
          }
          else {
            // loop through each object and get the values;
            let my_obj_arrays = jsonRow[attribute];
            //print_json("1.mapping my_obj_array:", my_obj_arrays);
            retJsonRow[attribute] = my_obj_arrays.map((val, idx) => {
              //print_json("my_obj_array:", val, debug);
              print_msg('2.parent:' + myId + ' parent_my_level:' + myLevel + 'parent(attribute):' + attribute + ' parent:' + parentName, debug);
              let nObj = {};
              IdMeAndMyDescendents(val, myId, myLevel, parentName, attribute, jsonRow, nObj, debug);
              //print_json("9000.nObj:", nObj, debug);
              return nObj;
            });
          }
          print_msg('---- converted --array -----', debug);
        }
        else if (jsonRow[attribute] instanceof Object) {
          let nObj = {};
          print_json('100.json_row:', jsonRow, debug);
          print_msg('101.parent:' + myId + ' parent_my_level:' + myLevel + 'parent(attribute):' + attribute + 'parent:' + parentName, debug);
          IdMeAndMyDescendents(jsonRow[attribute], myId, myLevel, parentName, attribute, jsonRow, nObj, debug);
          print_json('103.Child:', nObj, debug);
          retJsonRow[attribute] = nObj;
        }
        else if (!(jsonRow[attribute] instanceof Object)) {
          //print_json("attribute:" + attribute + " value:", json_row[attribute], debug);
          retJsonRow[attribute] = jsonRow[attribute];
        }
      }
    }
  }
}

function PrintJson(caption, jsonToPrint, debug = 1) {
  if (debug === 1) {
    console.log(`${caption}: ${JSON.stringify(jsonToPrint, null, 2)}`);
  }
}

function PrintMsg(msg, debug = 0) {
  if (debug === 1) {
    console.log(msg);
  }
}
