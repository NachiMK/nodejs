// Generate JSON Schema
import moment from 'moment';
import {
  s3FileExists,
  s3FileParser,
  uploadFileToS3,
  getS3JSON,
} from '../s3';
import { generateSchema } from './generateJsonSchema';
import odsLogger from '../log/ODSLogger';

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
  FilePrefix = '',
  Overwrite = 'Yes',
  RAWJsonSchemaFile = '',
}) => {
  const result = {
    status: {
      message: 'success',
    },
    error: {},
    Input: {
      Datafile,
      Output,
      FilePrefix,
      Overwrite,
      RAWJsonSchemaFile,
    },
  };

  try {
    if (!Datafile || Datafile.length === 0 || Datafile.substring(0, 2) !== 's3') {
      throw new Error(`Datafile file path invalid with value ${Datafile}. Please provide a valid AWS S3 path.`);
    }
    if (!Output || Output.length === 0 || Output.substring(0, 2) !== 's3') {
      throw new Error(`Output file path invalid with value ${Output}. Please provide a valid AWS S3 path.`);
    }
    if (!RAWJsonSchemaFile || RAWJsonSchemaFile.length === 0 || RAWJsonSchemaFile.substring(0, 2) !== 's3') {
      throw new Error(`RAWJsonSchemaFile file path invalid with value ${RAWJsonSchemaFile}. Please provide a valid AWS S3 path.`);
    }

    // get schema from data and combine that with Raw schema.
    const schemaByData = await generateRawSchemaFromData('', Datafile);
    const combinedSchema = await getCombinedSchema(schemaByData, RAWJsonSchemaFile);

    // throws an NoSuchKey error if file does not exist
    const fileJSON = parseSchemaJSON(combinedSchema);

    // Set up save file parameters
    const saveFileParams = s3FileParser(Output);
    let filename = `${saveFileParams.Key}${FilePrefix && FilePrefix.length ?
      FilePrefix.concat('-') : ''}${moment().format('YYYYMMDD_HHmmssSSS')}-schema.json`;
    filename = filename.replace('--', '-').replace('-_', '-');

    // Handle blocking overwrite if Overwrite is 'No'
    if (Overwrite.toLowerCase() === 'no') {
      const fileFound = await s3FileExists({
        Bucket: saveFileParams.Bucket,
        Key: filename,
      });

      if (fileFound) {
        throw new Error('File could not be overwritten. If you wish to overwrite this file, set Overwrite to "Yes"');
      }
    }

    await uploadFileToS3({
      Bucket: saveFileParams.Bucket,
      Key: filename,
      Body: JSON.stringify(fileJSON),
    });

    result.file = `s3://${saveFileParams.Bucket}/${filename}`;

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

async function getCombinedSchema(schemaFromData, RAWJsonSchemaFile) {
  const resp = {};
  if (schemaFromData && RAWJsonSchemaFile) {
    try {
      // do something
      const { Bucket, Key } = s3FileParser(RAWJsonSchemaFile);
      const rawJsonSchema = await getS3JSON({
        Bucket,
        Key,
      });
      if (rawJsonSchema) {
        Object.assign(schemaFromData, rawJsonSchema);
        resp.Status = 'success';
        resp.CombineSchema = schemaFromData;
      } else {
        throw new Error('RAW JSON Schema was not Found in S3 Path.', RAWJsonSchemaFile);
      }
    } catch (err) {
      resp.Status = 'error';
      resp.error = err;
      resp.CombineSchema = undefined;
      odsLogger.log('error', 'Error combining Schema', err.message);
    }
  } else {
    throw new Error(`Cannot combine schema either schemaFromData : ${schemaFromData} is null or RAWJsonSchemaFile Path is null: ${RAWJsonSchemaFile}`);
  }
  return resp;
}

async function generateRawSchemaFromData(Datafile) {
  let schema;
  try {
    // do something
    const { Bucket, Key } = s3FileParser(Datafile);
    const data = await getS3JSON({
      Bucket,
      Key,
    });
    if (data) {
      schema = await generateSchema('', data);
    }
  } catch (err) {
    schema = undefined;
    odsLogger.log('error', `Error getting data from data file to parse schema:${Datafile}, error: ${err.message}`);
    throw err.message;
  }
  return schema;
}
