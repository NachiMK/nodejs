// Generate JSON Schema
import _merge from 'lodash/merge';

import {
  s3FileParser,
} from '../s3';
import { generateSchema } from './generateJsonSchema';
import odsLogger from '../log/ODSLogger';
import { GetJSONFromS3Path, SaveJsonToS3File } from '../s3ODS';

// STEP - Parameter validation
//   Did you send me the data file name
//   Did you send me an output
//
//   {
//     Datafile: S3_filepath,
//     Output: S3_filepath,
//     FilePrefix: 123_prod_clients_yyyymmddhhmmss,
//     Overwrite: Yes, // Always overwrite unless "No" is found
//   }

// STEP - Get JSON data file from S3
//    error handling for file issues - no file, file empty
//    pass in an empty JSON schema file if file is empty
//
//    Example: poc/person-etl.json
//
//    transfer_type: string // always
//    db_type: any // need to figure out the mapping
//
//

// STEP - Output
//   {
//     status: {},
//     error: {},
//     file: S3 path,
//     Input: {}, // params of what was received to run the job
//   }


const getSchemaType = (type) => {
  if (Array.isArray(type)) {
    if (type.includes('object')) {
      return 'object';
    } else if (type.includes('string')) {
      return 'string';
    } else if (type.includes('number')) {
      return 'number';
    }

    return type.reduce((memo, key) => key, 'string');
  }

  return type || 'string';
};

const getSchemaDefaultValue = (type) => {
  const typeDefaultValue = {
    integer: -999999,
    number: -999999.99,
    string: '',
    boolean: false,
    default: '',
  };
  const defaultValue = typeDefaultValue[type];
  return type && Object.keys(typeDefaultValue).includes(type)
    ? defaultValue : '';
};

export const parseSchemaJSON = (data, parentKey) => {
  // If there is an object, we'll loop it
  if (data && data instanceof Object) {
    const { type, format, ...restData } = data;

    const setType = (type && !restData.$schema)
      ? getSchemaType(type) : null;

    const result = (parentKey !== 'items' && setType && setType !== 'object' && setType !== 'array') ? Object.assign({
      type: setType,
      default: getSchemaDefaultValue(setType),
      transfer_type: 'string',
      db_type: format || setType,
    }, restData) : {
      ...restData,
      ...(setType ? { type: setType } : {}),
    };

    return Object.keys(result).reduce((acc, key) => {
      const keyValue = result[key];

      // If this is an object and not an array, recurse
      if (!Array.isArray(keyValue) && keyValue instanceof Object) {
        acc[key] = parseSchemaJSON(keyValue, key);
      } else {
        acc[key] = keyValue;
      }
      return acc;
    }, {});
  }

  return data;
};

export default async ({
  Datafile,
  Output,
  Overwrite = 'Yes',
  S3RAWJsonSchemaFile = '',
  SaveDataSchemaToS3 = true,
}) => {
  const result = {
    status: {
      message: 'success',
    },
    error: {},
    Input: {
      Datafile,
      Output,
      Overwrite,
      S3RAWJsonSchemaFile,
      SaveDataSchemaToS3,
    },
  };

  try {
    if (!Datafile || Datafile.length === 0 || Datafile.substring(0, 2) !== 's3') {
      throw new Error(`Datafile file path invalid with value ${Datafile}. Please provide a valid AWS S3 path.`);
    }
    if (!Output || Output.length === 0 || Output.substring(0, 2) !== 's3') {
      throw new Error(`Output file path invalid with value ${Output}. Please provide a valid AWS S3 path.`);
    }
    if (!S3RAWJsonSchemaFile || S3RAWJsonSchemaFile.length === 0 || S3RAWJsonSchemaFile.substring(0, 2) !== 's3') {
      throw new Error(`S3RAWJsonSchemaFile file path invalid with value ${S3RAWJsonSchemaFile}. Please provide a valid AWS S3 path.`);
    }

    // get schema from data and combine that with Raw schema.
    const schemaByDataResp = await generateRawSchemaFromData({ Datafile, SaveDataSchemaToS3, Output });
    if (schemaByDataResp.Status && schemaByDataResp.Status === 'SUCCESS') {
      result.SchemaFileByData = schemaByDataResp.file || '';
    }
    const respCombinedSchema = await getCombinedSchema(schemaByDataResp.Schema, S3RAWJsonSchemaFile);

    // throws an NoSuchKey error if file does not exist
    if (!(respCombinedSchema && respCombinedSchema.Status
        && respCombinedSchema.Status === 'success' && respCombinedSchema.CombineSchema)) {
      throw new Error(`Schema from Data and Original Schema couldnt be combined.
      Error:${JSON.stringify(respCombinedSchema.error, null, 2)}`);
    }
    const fileJSON = parseSchemaJSON(respCombinedSchema.CombineSchema);

    // Save file in S3
    result.file = await SaveJsonToS3File(Output, fileJSON);
    return result;
  } catch (e) {
    result.status.message = 'error';
    if (e && e.code === 'NoSuchKey') {
      result.error = `Datafile ${Datafile} does not exist`;
    } else {
      result.error = e && e.message ? e.message : e;
    }

    return result;
  }
};

async function getCombinedSchema(schemaFromData, S3RAWJsonSchemaFile) {
  const resp = {};
  let rawJsonSchema;
  if (schemaFromData && schemaFromData.items && S3RAWJsonSchemaFile) {
    try {
      rawJsonSchema = await GetJSONFromS3Path(S3RAWJsonSchemaFile);
      if (rawJsonSchema) {
        rawJsonSchema = _merge(rawJsonSchema, schemaFromData.items.properties.Item);
        // rawJsonSchema = Object.assign(rawJsonSchema, schemaFromData.items.properties.Item);
        resp.Status = 'success';
        resp.CombineSchema = rawJsonSchema;
      } else {
        throw new Error('RAW JSON Schema was not Found in S3 Path.', S3RAWJsonSchemaFile);
      }
    } catch (err) {
      resp.Status = 'error';
      resp.error = err;
      resp.CombineSchema = undefined;
      odsLogger.log('error', 'Error combining Schema', err.message);
    }
  } else {
    throw new Error(`Cannot combine schema either schemaFromData : ${schemaFromData} is null or S3RAWJsonSchemaFile Path is null: ${S3RAWJsonSchemaFile}`);
  }
  return resp;
}

async function generateRawSchemaFromData({ Datafile, SaveDataSchemaToS3 = true, Output }) {
  const rawSchemaResp = {
    Status: 'Processing',
    file: undefined,
    Schema: undefined,
  };
  try {
    // do something
    const data = await GetJSONFromS3Path(Datafile);

    if (data) {
      rawSchemaResp.Schema = await generateSchema('', data);
      if (SaveDataSchemaToS3 && Output && rawSchemaResp.Schema) {
        // save file
        const saveFileParams = s3FileParser(Output);
        const s3PathToSave = `s3://${saveFileParams.Bucket}/${saveFileParams.Key}-bydata`;
        rawSchemaResp.file = await SaveJsonToS3File(s3PathToSave, rawSchemaResp);
        // response status
        rawSchemaResp.Status = 'SUCCESS';
      }
    }
  } catch (err) {
    rawSchemaResp.Status = 'error';
    rawSchemaResp.error = new Error(`Error getting schema from data file to parse:${Datafile}, error: ${err.message}`);
    odsLogger.log('error', rawSchemaResp.error);
    throw rawSchemaResp.error;
  }
  return rawSchemaResp;
}
