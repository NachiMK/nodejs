import { GetJSONFromS3Path, SaveJsonToS3File } from '../s3ODS';

const fillMissingKeys = require('object-fill-missing-keys');

export const JsonDataNormalizer = async (params = {}) => {
  const resp = {
    status: {
      message: 'SUCCESS',
    },
    file: params.Output,
    defaultSchemaFile: params.Output,
  };
  console.log(`Parameters for JsonDataNormalier: ${JSON.stringify(params)}`);

  try {
    const schemaFromS3 = await GetJSONFromS3Path(params.S3SchemaFile);
    const dataFromS3 = await GetJSONFromS3Path(params.S3DataFile);

    if (!(schemaFromS3) || !(dataFromS3)) {
      throw new Error(`No data either in Schema File: ${params.S3SchemaFile} or in Data File: ${params.S3DataFile}`);
    }

    const defaultSchema = ExtractOnlyMatchingKey(schemaFromS3, null, 'default');
    console.log('---------------- DEFAULT SCHEMA ----------');
    console.log(JSON.stringify(defaultSchema, null, 2));
    console.log('---------------- DEFAULT SCHEMA ----------');

    if (!defaultSchema) {
      throw new Error(`Default Schema from File: ${schemaFromS3} couldn't be extracted`);
    }

    const rowsFilled = AddMissingKeys(dataFromS3, defaultSchema);
    resp.file = await SaveJsonToS3File(params.Output, rowsFilled);
    resp.status.message = 'SUCCESS';
  } catch (err) {
    console.log(`Error in JsonDataNormalier: ${JSON.stringify(err.message, null, 2)}`);
    resp.status.message = 'error';
    resp.error = err;
  }

  // throw new Error(`Function not implemented. PayLoad:${params}`);
  return resp;
};

export const AddMissingKeys = (dataRows, defaultSchema) => {
  let localDataRows;
  if (dataRows) {
    localDataRows = dataRows.map((item) => {
      // console.log('item to process:', JSON.stringify(item, null, 2));
      if (item.Item) return Filldefaults(item.Item, defaultSchema);
      return Filldefaults(item, defaultSchema);
    });
    console.log('Default filled Entire Array', localDataRows);
  }
  console.log('---------------- FILLED ROWS ----------');
  console.log(JSON.stringify(localDataRows, null, 2));
  console.log('---------------- FILLED ROWS ----------');

  return localDataRows;
};

function Filldefaults(dataRow, defaultschema) {
  const result = fillMissingKeys(
    dataRow,
    defaultschema,
  );
  DeleteNullObjectsArrays(result);
  return result;
}

function DeleteNullObjectsArrays(jsonRow) {
  if (jsonRow instanceof Object) {
    Object.keys(jsonRow).forEach((prop) => {
      if (JSON.stringify(jsonRow[prop]).localeCompare('null') === 0) {
        delete jsonRow[prop];
      }
    });
  }
}

export function ExtractOnlyMatchingKey(odsSchema, parentKey, keyName) {
  const retObjSchema = {};
  console.log(`Parameters defined: Obj: ${(odsSchema)}, Parent: ${(parentKey)}`);
  if (odsSchema.properties) {
    Object.keys(odsSchema.properties).forEach((objectKey) => {
      const currAttributeObj = odsSchema.properties[objectKey];
      // proceed if type is defined.
      if ((currAttributeObj.type) && (currAttributeObj.type !== 'undefined')) {
        // get the type
        const typeOfObj = currAttributeObj.type.toLocaleLowerCase();
        // based on type get default or recurse
        switch (typeOfObj) {
          case 'object':
            retObjSchema[objectKey] = ExtractOnlyMatchingKey(currAttributeObj, objectKey, keyName);
            break;
          case 'array':
            // do we have array of objects or array of props?
            retObjSchema[objectKey] = [];
            if (currAttributeObj.items.type.localeCompare('object') === 0) {
              const objInArray = ExtractOnlyMatchingKey(currAttributeObj.items, undefined, keyName);
              retObjSchema[objectKey].push(objInArray);
            }
            break;
          default:
            retObjSchema[objectKey] = currAttributeObj[keyName];
        }
      }
    });
  }// has property check
  return retObjSchema;
}
