'use strict';
// var AWS = require('aws-sdk');
var _ = require('lodash');
const jsonfile = require('jsonfile');
var jsschemafile = jsonfile.readFileSync('persons-complex-single.json');
var empty = require('json-schema-empty');


// PARAMETERS TO THIS SCRIPT.
const input_data_file = './persons_unit_test_data.json';
const output_csv_path = "./output/";
const output_default_schema_file = output_csv_path + "persons-etl-default.json";
const output_default_data_file = output_csv_path + "default_persons.json";
// this will be passed in.
const batchid = Math.floor(Math.random() * 100000);

// AWS.config.update({
//     region: "us-west-2",
//     endpoint: "https://dynamodb.us-west-2.amazonaws.com"
//   });

// dont assign table_name. It will be figured from the input file.
var table_name;
table_name = getRootObjectName(input_data_file, 0);
print_msg("table name after setting:" + table_name, 0);

const batch_key = "ODS_Batch_Id";
const batch_unique_key_name = "ODS_Id";
//const parent_key_refix = "ODS_Parent_Id_";
//const parent_table_name_key_prefix = "ODS_Parent_Table_";
const default_parent_path = "ODS_Parent_Path";
const default_parent_Uri = "ODS_Parent_Uri";
const default_Uri = "ODS_Uri";
const default_Uri_Path = "ODS_Path";
let batch_unique_id = 0;

print_msg("scanJSONSchema Recursive printing.....", 1);
scanJSONSchema(jsschemafile.properties, jsschemafile);
//jsonfile.writeFileSync("persons-etl-single.json", jsschemafile, { spaces: 2});
print_msg("scanJSONSchema Recursive printing.....", 1);

print_msg("default value recursion...", 1);
var defschema = getDefaultSchema(jsschemafile, null);
jsonfile.writeFileSync(output_default_schema_file, defschema, { spaces: 2 });
print_msg("default value recursion...", 1);
print_json("Default schema...", defschema, 0);

print_msg("Fill missing keys...", 1);
let json_data_from_input = getRows(input_data_file);
let RowsArray = addmissingkeys(json_data_from_input, defschema, 0);
let def_data_file = {};
def_data_file[table_name] = RowsArray;
jsonfile.writeFileSync(output_default_data_file, def_data_file, { spaces: 2 });
print_json("Fill missing keys...", def_data_file, 0);

print_msg("Normalized tables...", 1);
let normalized_tables = {};
getNormalizedDataset(RowsArray, table_name, normalized_tables, 0);
print_json("Normalized tables...", Object.keys(normalized_tables), 0);

print_msg("Persit Tables...", 1);
createFiles(normalized_tables, batchid, table_name, output_csv_path, 1);
print_msg("Files created....", 1);

function createFiles(normalized_tables, batch_key, file_prefix, path_to_save, debug = 0) {
    // loop through each array or objects
    // persist all items to csv files.
    let seq = 0;
    Object.keys(normalized_tables).forEach(function (tablename) {
        let filename = getUniqueFileName(file_prefix, batch_key, tablename, seq++);
        CreateCSVFile(normalized_tables[tablename], tablename, filename, path_to_save, debug);
        print_msg("File name:" + filename, debug);
    });
}

function CreateCSVFile(rowsArray, tablename, filename, filepath, options = {}, debug = 0) {
    if (rowsArray) {
        let path = require('path');
        let fullfilename = path.join(filepath, filename);
        print_msg("File:" + fullfilename + " to be created.", debug);
        const json2csv = require('json2csv').parse;
        try {
            const csv = json2csv(rowsArray, {});
            const file_writer = require('fs');
            file_writer.writeFileSync(fullfilename, csv);
            print_msg("File:" + fullfilename + " created.", debug);
        } catch (err) {
            print_msg(err, debug)
        }
    }
}

function getDefaultSchema(etl_schema, parentkey) {
    var return_obj_schema = {};
    if (etl_schema.hasOwnProperty("properties")) {
        //print_msg("Has properties.");
        for (var schemaproperties in etl_schema.properties) {
            var curr_attribute_obj = etl_schema.properties[schemaproperties];
            var index_of_type = Object.keys(curr_attribute_obj).indexOf("type", 0);
            //print_msg("Looping.." + schemaproperties + ", Check for index of type:"+JSON.stringify(curr_attribute_obj));
            //if (typeof(schemaproperties) == "object"){
            //print_msg("It is an object..");
            if ((index_of_type >= 0) && (curr_attribute_obj.type !== "undefined")) {
                // get the type
                var type_of_obj = curr_attribute_obj.type.toLocaleLowerCase();
                // based on type get default or recurse
                switch (type_of_obj) {
                    case "object":
                        //print_msg("Object key:" + schemaproperties + ", default:recrusion");
                        return_obj_schema[schemaproperties] = getDefaultSchema(curr_attribute_obj, schemaproperties);
                        break;
                    case "array":
                        var emptyarray = [];
                        //print_msg("Array key:" + schemaproperties + ", Array default:" + emptyarray);
                        return_obj_schema[schemaproperties] = emptyarray;
                        // do we have array of objects or array of props?
                        if (curr_attribute_obj.items.type.localeCompare("object") == 0) {
                            var objInArray = {};
                            objInArray = getDefaultSchema(curr_attribute_obj.items);
                            //print_msg("Array key:" + schemaproperties + ", objInArray default:" + JSON.stringify(objInArray));
                            emptyarray.push(objInArray);
                        }
                        return_obj_schema[schemaproperties] = emptyarray;
                        break;
                    default:
                        //print_msg("key:" + schemaproperties + ", default:" + curr_attribute_obj.default);
                        return_obj_schema[schemaproperties] = curr_attribute_obj.default;
                }
            }
            //} //typeof object check
        } //for each prop loop
    } // has property check
    return return_obj_schema;
}

function getUniqueFileName(file_prefix, batch_key, tablename, seq_number = 0, extension = ".csv", addDateTime = true) {
    let dtmFormat = getDateTimeFormat();
    let filename = file_prefix + "_" + batch_key + "_" + pad(seq_number, 2) + "_" + tablename + "_" + dtmFormat + extension;
    return filename;
}

function pad(num, size) {
    var s = "000000000" + num;
    return s.substr(s.length - size);
}

function getDateTimeFormat() {
    return new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '').replace(/-/g, '').replace(/:/g, '').replace(/ /g, '');
}

function scanJSONSchema(obj, parentkey) {
    var k;
    var defaultvalue = "";
    var type_from_format = "";
    var had_format = false;
    if (obj instanceof Object) {
        had_format = false;
        type_from_format = "";
        for (k in obj) {
            if (obj.hasOwnProperty(k)) {

                // do we have a format, if so we can use it as data type
                if ((Object.keys(obj).indexOf("format", 0) >= 0) && (obj.format !== "undefined")) {
                    type_from_format = obj.format;
                    delete obj.format;
                    had_format = true;
                }

                //recursive call to scan property
                if ((Object.keys(obj).indexOf("type", 0) >= 0) && (obj.type !== "undefined")) {
                    if (typeof (obj.type) === 'object') {
                        var db_data_type = "";
                        obj.type.forEach(element => {
                            if (element.localeCompare('object') == 0) {
                                db_data_type = element;
                            }
                            else if (element.localeCompare('string') == 0 && db_data_type.localeCompare('object') != 0) {
                                db_data_type = element;
                            }
                            else if ((db_data_type.localeCompare('string') != 0) && (element.localeCompare('null') != 0)) {
                                db_data_type = element;
                            }
                            else if (element.localeCompare('null') != 0) {
                                db_data_type = element;
                            }
                        });

                        delete obj.type;
                        obj["type"] = db_data_type;
                    }

                    if ((obj.type.localeCompare("array") != 0) && (obj.type.localeCompare("object") != 0)
                        && (parentkey.localeCompare("items") != 0)) {

                        var strtype = obj.type.toLocaleLowerCase();
                        switch (strtype) {
                            case "string":
                                defaultvalue = "";
                                break;
                            case "number":
                                defaultvalue = -999999.99;
                                break;
                            case "integer":
                                defaultvalue = -999999;
                                break;
                            case "boolean":
                                defaultvalue = false;
                                break;
                            default:
                                defaultvalue = "";
                        }
                        obj["default"] = defaultvalue;
                        defaultvalue = "";
                        obj["transfer_type"] = "string";
                        obj["db_type"] = obj.type;
                        if (had_format == true) {
                            obj["db_type"] = type_from_format;
                        }
                    }
                }
                scanJSONSchema(obj[k], k);
            }
        }
    }

};

function addmissingkeys(data_rows, defaultschema, debug = 0) {
    let array_of_rows = data_rows;
    //print_msg("what is it:" + typeof(array_persons));
    array_of_rows = array_of_rows.map(function Filldefaults(data_row) {
        const fillMissingKeys = require('object-fill-missing-keys');
        const result = fillMissingKeys(
            data_row,
            defaultschema,
            {
                doNotFillThesePathsIfTheyContainPlaceholders: ['Benefits', 'Spouse'],
                placeholder: null,
            }
        )
        print_json("Default Filled:", result, debug);
        //const result = Object.assign(data_row, defaultschema);
        delete_null_objects_arrays(result);
        return result;
    });
    print_json("Default filled Entire Array", array_of_rows, debug);
    return array_of_rows;
}

function delete_null_objects_arrays(json_row) {
    if (json_row instanceof Object) {
        for (let prop in json_row) {
            //print_msg("Key:" + prop + " value:" + JSON.stringify(json_row[prop], null, 2) + " may be deleted.");
            if (JSON.stringify(json_row[prop]).localeCompare("null") == 0) {
                //print_msg("Key:" + prop + " value:" + json_row.prop + " will be deleted.");
                delete json_row[prop];
            }
        }
    }
    return;
}

function getRootObjectName(input_file_name, debug = 0) {
    const dataset = require(input_file_name);
    print_msg("table_name before setting:" + table_name + " file:" + input_file_name, debug);
    if (_.isUndefined(table_name) || (table_name.length === 0)) {
        if (dataset) {
            // should be exactly one
            let rootObjectKeys = Object.keys(dataset);
            if (rootObjectKeys.length === 1) {
                table_name = rootObjectKeys[0];
            }
            else {
                throw new Error("File has too many root objects. Cannot be processed. Please fix file.");
            }
        }
        else {
            throw new Error("File has too many root objects. Cannot be processed. Please fix file.");
        }
    }
    print_msg("table name after:" + table_name, debug)
    return table_name;
}

function getRows(input_file_name) {
    let rootname = getRootObjectName(input_file_name);
    const dataset = require(input_file_name);
    if ((dataset) && (dataset.hasOwnProperty(rootname))) {
        // should be exactly one
        let return_array = dataset[rootname];
        return return_array;
    }
    else {
        throw new Error("Invalid data file!");
    }
    return;
}

function getNormalizedDataset(rowsArray, table_name, normalized_dataset, debug = 0) {

    let parent_key;
    let parent_object = null;
    let rowsArray_with_Ids = [];

    if (rowsArray) {
        //object has any items
        if (rowsArray.length > 0) {
            rowsArray.forEach(function (json_row) {
                let json_row_with_id = {};
                if (!(_.isEmpty(json_row))) {
                    let parent_level = -1;
                    //print_json("input:json_row:", json_row, debug);
                    IdMeAndMyDescendents(json_row, parent_key, parent_level, table_name, table_name, parent_object, json_row_with_id, debug);
                    rowsArray_with_Ids.push(_.cloneDeep(json_row_with_id));
                    print_json("json_row_with_id:", _.cloneDeep(json_row_with_id), debug);
                    return;
                }
            })
        }
    }
    print_json("rows with IDs:", rowsArray_with_Ids.length, debug);

    if (rowsArray_with_Ids) {
        //object has any items
        if (rowsArray_with_Ids.length > 0) {
            // testing.
            // normalizeMe(_.cloneDeep(rowsArray_with_Ids[0]), "root", normalized_dataset,1);
            // print_json(" normalized: ", normalized_dataset, 1);
            rowsArray_with_Ids.forEach(function (json_row_with_id) {
                if (!(_.isEmpty(json_row_with_id))) {
                    normalizeMe(_.cloneDeep(json_row_with_id), table_name, normalized_dataset, debug);
                    return;
                }
            });

        }
    }

    return;
}

function normalizeMe(json_to_normalize, table_name, dataset, debug = 0) {

    let local_copy = json_to_normalize;
    print_json("normalizeMe input:", local_copy, debug);

    if (table_name.length > 0) {
        // create a new array
        if (!(dataset.hasOwnProperty(table_name))) {
            dataset[table_name] = [];
        }
    }
    print_msg("Table:" + table_name, debug);
    if (local_copy) {
        if (!(_.isEmpty(local_copy))) {

            if (HasSimpleTypes(local_copy)) {
                let obj = {};
                // extract all properties of simple data types and add to our current table and return
                for (var attribute in local_copy) {
                    print_msg("attribute:" + attribute, debug);
                    print_msg("type of:" + typeof (local_copy[attribute]), debug);
                    if (!(typeof (local_copy[attribute]) === "object")) {
                        obj[attribute] = local_copy[attribute];
                        print_json("Added:" + attribute + "Value:", local_copy[attribute], debug);
                        delete local_copy[attribute];
                    }
                }
                // add to array
                dataset[table_name].push(obj);
            }

            for (var attribute in local_copy) {
                if (local_copy[attribute] instanceof Array) {
                    if (IsArrayOfSimpleTypes(local_copy[attribute])) {
                        throw "Objects that were cleaned shouldn't have simple arrays.";
                    }
                    else {
                        // loop through each object and get the values;
                        let my_obj_arrays = local_copy[attribute];
                        print_msg("processing elements of:" + attribute, debug);
                        print_msg("# of elements to process:" + my_obj_arrays.length, debug);
                        my_obj_arrays.map((val, idx) => {
                            //print_json("processing array element:", val, debug);
                            normalizeMe(val, attribute, dataset);
                            return;
                        });
                        delete local_copy[attribute];
                    }
                }
                else if (local_copy[attribute] instanceof Object) {
                    print_msg("processing attributes of object:", attribute, debug);
                    normalizeMe(local_copy[attribute], attribute, dataset);
                    delete local_copy[attribute];
                }
            }

        }
    }
    return;
}

function IdMeAndMyDescendents(json_row, parent_id, parent_level, parent_name, my_name, parent_object, ret_json_row, debug = 0) {

    // if no parent then we are the root.
    let my_level = parent_level + 1;
    print_msg("At Start: parent_level:" + parent_level + " my_level:" + my_level, debug);

    if (json_row) {
        if (!(_.isEmpty(json_row))) {
            // add ods details
            addBatchId(json_row);
            addBatchUniqueId(json_row, my_name, debug);
            let my_id = json_row[batch_unique_key_name];

            //root - process default values for root. So recursion can take of the rest.
            if (IsRootObject(parent_level, parent_object)) {
                // Add root representation for parent which would be simply a slash.
                // Parent value would be -1
                addDefaultParent(json_row);
            }

            // add parent if needed to given object.
            addParentIdToChildObject(parent_id, parent_level, parent_object, parent_name, json_row, debug);
            parent_name = my_name;
            // check if it is a simple property/array/object
            for (var attribute in json_row) {
                if (json_row[attribute] instanceof Array) {
                    print_msg("---- converting --array ----- parent: " + parent_name + " attribute:" + attribute, debug);
                    if (IsArrayOfSimpleTypes(json_row[attribute])) {
                        //let my_parent = getNewParentParamObject(my_id, my_name, my_level, json_row, debug);
                        ret_json_row[attribute] = convertSimpleArrayToObjects(json_row[attribute], my_id, my_level, parent_name, attribute, json_row, debug);
                    }
                    else {
                        // loop through each object and get the values;
                        let my_obj_arrays = json_row[attribute];
                        //print_json("1.mapping my_obj_array:", my_obj_arrays);
                        ret_json_row[attribute] = my_obj_arrays.map((val, idx) => {
                            //print_json("my_obj_array:", val, debug);
                            print_msg("2.parent:" + my_id + " parent_my_level:" + my_level + "parent(attribute):" + attribute + " parent:" + parent_name, debug);
                            let nObj = {};
                            IdMeAndMyDescendents(val, my_id, my_level, parent_name, attribute, json_row, nObj, debug);
                            //print_json("9000.nObj:", nObj, debug);
                            return nObj;
                        });
                    }
                    print_msg("---- converted --array -----", debug);
                }
                else if (json_row[attribute] instanceof Object) {
                    let nObj = {};
                    print_json("100.json_row:", json_row, debug);
                    print_msg("101.parent:" + my_id + " parent_my_level:" + my_level + "parent(attribute):" + attribute + "parent:" + parent_name, debug);
                    IdMeAndMyDescendents(json_row[attribute], my_id, my_level, parent_name, attribute, json_row, nObj, debug);
                    print_json("103.Child:", nObj, debug);
                    ret_json_row[attribute] = nObj;
                }
                else if (!(json_row[attribute] instanceof Object)) {
                    //print_json("attribute:" + attribute + " value:", json_row[attribute], debug);
                    ret_json_row[attribute] = json_row[attribute];
                }
            }
        }
    }
    return;
}

function getNewParentParamObject(parentId, parentName, parentLevel, parentObject, debug = 0) {
    let p = {
        parent_id: parentId,
        parent_name: parentName,
        parent_level: parentLevel,
        parent: parentObject
    }
}

function IsRootObject(level, objectToCheck) {
    if ((level === -1) && (_.isUndefined(objectToCheck))) {
        return true;
    }
    return false;
}

function addDefaultParent(objectToAdd) {
    if (objectToAdd) {
        if (objectToAdd.hasOwnProperty(default_parent_path)) {
            objectToAdd[default_parent_path] = "/";
        }
    }
}

function IsArrayOfSimpleTypes(arrayToTest) {
    let retval = false;
    if (arrayToTest.length > 0) {
        let hasObject = false;
        hasObject = arrayToTest.some(function (val, idx) {
            return val instanceof Object;
        });
        retval = !hasObject;
    }
    return retval;
}

function IsObjectOfSimpleTypes(objToTest) {
    let retVal = true;
    if (objToTest) {
        for (var attribute in objToTest) {
            if ((objToTest[attribute] instanceof Array) || (objToTest[attribute] instanceof Object)) {
                retVal = false;
                return retVal;
            }
        }
    }
    return retVal;
}

function HasSimpleTypes(objToTest) {
    let retVal = false;
    if (objToTest) {
        for (var attribute in objToTest) {
            if (!((objToTest[attribute] instanceof Array) || (objToTest[attribute] instanceof Object))) {
                retVal = true;
                return retVal;
            }
        }
    }
    return retVal;
}

function convertSimpleArrayToObjects(array_of_simple_datatypes, parent_id, parent_level, parent_name, my_name, parent_object, debug = 0) {
    let ret_arr = [];
    // is an array check
    if (array_of_simple_datatypes instanceof Array) {
        //array has some elements
        if (array_of_simple_datatypes.length > 0) {
            // only if array has simple object proceed or else we need to process it differently.
            //print_json("Array element value: ", array_of_simple_datatypes[0]);
            if (!(array_of_simple_datatypes[0] instanceof Object)) {
                ret_arr = array_of_simple_datatypes.map((val, idx) => {
                    var obj = getNewObjectFromArrayElement(val, idx, my_name, debug);
                    print_json("My parent at level: " + parent_level + " in array conversion:", parent_object, debug);
                    addParentIdToChildObject(parent_id, parent_level, parent_object, parent_name, obj, debug);
                    print_json("Array after adding parent: ", obj, debug);
                    return obj;
                });
            }
            else {
                ret_arr = array_of_simple_datatypes.map((val, idx) => {
                    throw new Error("Array of objects in method that can process only array of simple types");
                    var obj = addParentIdToChildObject(parent_id, parent_level, parent_object, parent_name, val, debug);
                    return obj;
                })
            }
        }
    }
    return ret_arr;
}

function addParentIdToChildObject(parent_id, parent_level, parent_object, parent_name, child_obj, debug = 0) {
    if (parent_level < 0) {
        parent_level = 0;
    }
    //let parent_key_name = parent_key_refix + parent_level;
    //let parent_table_name = parent_table_name_key_prefix + parent_level;

    print_json("Who am i:", child_obj, debug);
    print_json("ParentId:", parent_id, debug);
    print_json("Parent_level:", parent_level, debug);
    print_msg("parent_name:" + parent_name, debug);

    if ((child_obj) && (!_.isUndefined(parent_id))) {
        //let parent_name_alias = parent_name + "." + batch_unique_key_name;
        //let parent_ods_path_alias = parent_name + "." + default_parent_path;

        //child_obj[parent_name_alias] = parent_id;
        child_obj[default_parent_path] = "/" + parent_name;
        child_obj[default_parent_Uri] = "/" + parent_id;
        //child_obj[parent_key_name] = parent_id;
        //child_obj[parent_table_name] = parent_name;
        print_json("after adding parent at level: " + parent_level + " to me :", child_obj, debug);
        if ((parent_object) && (parent_level > 0)) {
            print_msg("adding my ancestors.", debug);
            //get all parent's parent_level_* props and add to me.
            let start_idx = parent_level - 1;
            let end_idx = 0;

            //child_obj[parent_ods_path_alias] = parent_object[default_parent_path];
            child_obj[default_parent_path] = parent_object[default_parent_path] + child_obj[default_parent_path];
            child_obj[default_parent_Uri] = parent_object[default_parent_Uri] + child_obj[default_parent_Uri];

            // print_msg("my parent's parent, start idx (parent_level -1):" + start_idx + " parent level:" + parent_level, debug);
            // while((start_idx >= end_idx) && (start_idx >= 0)){
            //     let key_name = parent_key_refix + start_idx;
            //     let parent_tbl_name = parent_table_name_key_prefix + start_idx;
            //     if (parent_object.hasOwnProperty(key_name)){
            //         // add to me
            //         print_msg("my parent's parent, key:" + key_name + " value:" + parent_object[key_name], debug);
            //         child_obj[key_name] = parent_object[key_name];
            //         child_obj[parent_tbl_name] = parent_object[parent_tbl_name];
            //     }
            //     start_idx--;
            // }
        }
        updateUri(child_obj, debug);
        //if (!child_obj.hasOwnProperty(parent_key_name)){}
    }
    print_json("Who am i after update:", child_obj, debug);
}

function getNewObjectFromArrayElement(val, idx, array_name, debug = 0) {
    var obj = {};
    obj.ArrayIndex = idx;
    obj.ArrayValue = val;
    addBatchId(obj);
    addBatchUniqueId(obj, array_name, debug);
    print_json("obj", obj, debug);
    return obj;
}

function getBatchUniqueId() {
    return batch_unique_id++;
}

function addBatchId(obj_to_add) {
    if (!_.isUndefined(obj_to_add) && _.isObject(obj_to_add)) {
        if (!obj_to_add.hasOwnProperty(batch_key)) {
            obj_to_add[batch_key] = batchid;
        }
    }
}

function addBatchUniqueId(obj_to_add, obj_name, debug = 0) {
    if (!_.isUndefined(obj_to_add) && _.isObject(obj_to_add)) {
        if (!obj_to_add.hasOwnProperty(batch_unique_key_name)) {
            obj_to_add[batch_unique_key_name] = getBatchUniqueId();
        }
        if (!obj_to_add.hasOwnProperty(default_Uri)) {
            obj_to_add[default_Uri] = "/" + obj_to_add[batch_unique_key_name];
        }
        addUriPath(obj_to_add, obj_name);
        print_json("my keys added:", obj_to_add, debug);
    }
}

function addUriPath(obj_to_add, obj_name) {
    if (!_.isUndefined(obj_to_add) && _.isObject(obj_to_add)) {
        if (!obj_to_add.hasOwnProperty(default_Uri_Path)) {
            obj_to_add[default_Uri_Path] = "/" + obj_name;
        }
    }
}

function updateUri(obj_to_update, debug = 0) {
    if (!_.isUndefined(obj_to_update) && _.isObject(obj_to_update)) {
        if (obj_to_update.hasOwnProperty(default_Uri)) {
            obj_to_update[default_Uri] = obj_to_update[default_parent_Uri] + obj_to_update[default_Uri];
        }
        if (obj_to_update.hasOwnProperty(default_Uri_Path)) {
            obj_to_update[default_Uri_Path] = obj_to_update[default_parent_path] + obj_to_update[default_Uri_Path];
        }
    }
    print_json("Uri updated", obj_to_update, debug);
}

function print_json(caption, json_to_print, debug = 1) {
    if (debug == 1) {
        console.log(caption + ":" + JSON.stringify(json_to_print, null, 2));
    }
}

function print_msg(msg, debug = 0) {
    if (debug == 1) {
        console.log(msg);
    }
}
