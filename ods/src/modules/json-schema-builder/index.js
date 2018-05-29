// Generate JSON Schema
import moment from 'moment'
import {
  getS3JSON,
  s3FileExists,
  s3FileParser,
  uploadFileToS3,
} from '../s3'

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
      return 'object'
    } else if (type.includes('string')) {
      return 'string'
    } else if (type.includes('number')) {
      return 'number'
    }

    return type.reduce((memo, key) => key, 'string')
  }

  return type || 'string'
}

const getSchemaDefaultValue = (type) => {
  const typeDefaultValue = {
    integer: -999999,
    number: -999999.99,
    string: '',
    boolean: false,
    default: '',
  }
  const defaultValue = typeDefaultValue[type]
  return type && Object.keys(typeDefaultValue).includes(type)
    ? defaultValue : ''
}

export const parseSchemaJSON = (data, parentKey) => {
  // If there is an object, we'll loop it
  if (data && data instanceof Object) {
    const { type, format, ...restData } = data

    const setType = (type && !restData.$schema)
      ? getSchemaType(type) : null

    const result = (parentKey !== 'items' && setType && setType !== 'object' && setType !== 'array') ? Object.assign({
      type: setType,
      default: getSchemaDefaultValue(setType),
      transfer_type: 'string',
      db_type: format || setType,
    }, restData) : {
      ...restData,
      ...(setType ? { type: setType } : {})
    }

    return Object.keys(result).reduce((acc, key) => {
      const keyValue = result[key]

      // If this is an object and not an array, recurse
      if (!Array.isArray(keyValue) && keyValue instanceof Object) {
        acc[key] = parseSchemaJSON(keyValue, key)
      } else {
        acc[key] = keyValue
      }
      return acc
    }, {})
  }

  return data
}

export default async ({
  Datafile,
  Output,
  FilePrefix = '',
  Overwrite = 'Yes',
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
    },
  }

  try {
    if (!Datafile || Datafile.length === 0 || Datafile.substring(0, 2) !== 's3') {
      throw `Datafile file path invalid with value ${Datafile}. Please provide a valid AWS S3 path.`
    }
    if (!Output || Output.length === 0 || Output.substring(0, 2) !== 's3') {
      throw `Output file path invalid with value ${Output}. Please provide a valid AWS S3 path.`
    }

    // Get the Datafile from s3
    // throws an NoSuchKey error if file does not exist
    const { Bucket, Key } = s3FileParser(Datafile)
    const fileJSON = parseSchemaJSON(await getS3JSON({
      Bucket,
      Key,
    }))

    // Set up save file parameters
    const saveFileParams = s3FileParser(Output)
    const filename = `${saveFileParams.Key}${FilePrefix && FilePrefix.length ?
      FilePrefix.concat('-') : ''}${moment().format('YYYYMMDDhhmmss')}-schema.json`

    // Handle blocking overwrite if Overwrite is 'No'
    if (Overwrite.toLowerCase() === 'no') {
      const fileFound = await s3FileExists({
        Bucket: saveFileParams.Bucket,
        Key: filename,
      })

      if (fileFound) {
        throw 'File could not be overwritten. If you wish to overwrite this file, set Overwrite to "Yes"'
      }
    }

    await uploadFileToS3({
      Bucket: saveFileParams.Bucket,
      Key: filename,
      Body: JSON.stringify(fileJSON),
    })

    result.file = `s3://${saveFileParams.Bucket}/${filename}`

    return result
  } catch (e) {
    result.status.message = 'error'
    if (e && e.code === 'NoSuchKey') {
      result.error = `Datafile ${Datafile} does not exist`
    } else {
      result.error = e && e.message ? e.message : e
    }

    return result
  }
}


