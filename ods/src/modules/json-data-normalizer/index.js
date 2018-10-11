import _isEmpty from 'lodash/isEmpty'
import { JsonMissingKeyFiller } from '../json-missing-key-filler/index'
import { JsonToJsonFlattner } from '../json-to-json-flattner/JsonToJsonFlattner'
import { PreDefinedAttributeEnum } from '../../modules/ODSConstants/AttributeNames'

export const JsonDataNormalizer = async (params = {}) => {
  const resp = {
    status: {
      message: 'processing',
    },
    error: undefined,
    S3UniformJSONFile: undefined,
    S3FlatJsonFile: undefined,
    JsonKeysAndPath: {},
  }
  let objMissingKeyFiller
  console.log(`Parameters for JsonDataNormalier: ${JSON.stringify(params)}`)

  ValidateParams(params)
  const s3UniformJsonFileEnum = PreDefinedAttributeEnum.S3UniformJSONFile.value
  const s3FlatJsonFileEnum = PreDefinedAttributeEnum.S3FlatJsonFile.value

  try {
    objMissingKeyFiller = new JsonMissingKeyFiller(getParamsForFillingMissedKeys(params))
    await objMissingKeyFiller.getUniformJsonData()
    if (!objMissingKeyFiller.S3UniformJsonFile || _isEmpty(objMissingKeyFiller.S3UniformJsonFile)) {
      throw new Error('JsonMissingKeyFiller didnt throw error but didnt return a file.')
    }
    resp[s3UniformJsonFileEnum] = objMissingKeyFiller.S3UniformJsonFile
  } catch (err) {
    resp.status.message = 'error'
    resp.error = new Error(`Error in getting Uniform Json Data, ${err.message}`)
    throw new Error(resp.error.message)
  }

  // did we create a file successfully? if so let us flaten it.
  try {
    if (resp[s3UniformJsonFileEnum]) {
      // let us flatten the data
      const flatParams = getParamsToFlattenJson(params)
      flatParams.S3DataFilePath = resp[s3UniformJsonFileEnum]
      const objJsonFlatner = new JsonToJsonFlattner(flatParams)
      await objJsonFlatner.SaveNormalizedData()
      if (!objJsonFlatner.Output.NormalizedS3Path) {
        throw new Error('JsonToJsonFlattner didnt throw error but didnt return a file.')
      }
      resp[s3FlatJsonFileEnum] = objJsonFlatner.Output.NormalizedS3Path
      //get keys and paths
      Object.assign(resp.JsonKeysAndPath, objJsonFlatner.Output.JsonKeysAndPath)
      resp.status.message = 'success'
    }
  } catch (err) {
    resp.status.message = 'error'
    resp.error = new Error(`Error in getting Flat Json Data, ${err.message}`)
    throw new Error(resp.error.message)
  }
  // return
  return resp
}

function getParamsForFillingMissedKeys(params) {
  return {
    S3DataFile: params.S3DataFile,
    Overwrite: 'yes',
    S3SchemaFile: params.S3SchemaFile,
    S3OutputBucket: params.S3OutputBucket,
    S3OutputKey: params.S3UniformJsonPrefix,
    LogLevel: params.LogLevel || 'warn',
    DoNotfillEmptyObjects: true,
  }
}

function getParamsToFlattenJson(params) {
  return {
    Overwrite: 'yes',
    S3OutputBucket: params.S3OutputBucket,
    S3OutputKey: params.S3FlatJsonPrefix,
    TableName: params.TableName,
    BatchId: params.BatchId,
    OutputType: 'Save-to-S3',
    LogLevel: params.LogLevel || 'warn',
    S3DataFilePath: undefined,
  }
}

function ValidateParams(params = {}) {
  if (!params.S3DataFile) {
    throw new Error('Invalid Param: S3DataFile is required for JsonDataNormalizer')
  }
  if (!params.S3SchemaFile) {
    throw new Error('Invalid Param: S3SchemaFile is required for JsonDataNormalizer')
  }
  if (!params.S3OutputBucket) {
    throw new Error('Invalid Param: S3OutputBucket is required for JsonDataNormalizer')
  }
  if (!params.S3UniformJsonPrefix) {
    throw new Error('Invalid Param: S3UniformJsonPrefix is required for JsonDataNormalizer')
  }
  if (!params.S3FlatJsonPrefix) {
    throw new Error('Invalid Param: S3FlatJsonPrefix is required for JsonDataNormalizer')
  }
  if (!params.TableName) {
    throw new Error('Invalid Param: TableName is required for JsonDataNormalizer')
  }
  if (!params.BatchId) {
    throw new Error('Invalid Param: BatchId is required for JsonDataNormalizer')
  }
}
