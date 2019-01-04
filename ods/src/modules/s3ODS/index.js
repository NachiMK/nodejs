import _ from 'lodash'
import moment from 'moment'
import {
  s3FileParser,
  uploadFileToS3,
  s3BucketFactory,
  s3FileExists,
  copyS3toS3,
  moveS3toS3,
  DeleteFile,
} from '../s3/index'

export const GetJSONFromS3Path = async (s3FilePath) => {
  try {
    const { Bucket, Key } = await s3FileParser(s3FilePath)

    if (_.trim(Bucket).length <= 0 || _.trim(Key).length <= 0) {
      throw new Error(
        `Either Bucket ${Bucket} or Key: ${Key} is empty. Need Bucket and Key to Load file.`
      )
    }

    const file = await s3BucketFactory(Bucket)(Key)
    return JSON.parse(file.Body)
  } catch (e) {
    const msg = `Error loading data from s3 Path:${s3FilePath}, error: ${e.message}`
    console.log(msg)
    throw new Error(msg)
  }
}

export const GetStringFromS3Path = async (s3FilePath) => {
  try {
    const { Bucket, Key } = await s3FileParser(s3FilePath)
    if (_.trim(Bucket).length <= 0 || _.trim(Key).length <= 0) {
      throw new Error(
        `Either Bucket ${Bucket} or Key: ${Key} is empty. Need Bucket and Key to Load file.`
      )
    }
    const file = await s3BucketFactory(Bucket)(Key)
    return file.Body.toString('utf-8')
  } catch (e) {
    const msg = `Error loading data from s3 Path:${s3FilePath}, error: ${e.message}`
    console.log(msg)
    throw new Error(msg)
  }
}

export async function SaveJsonToS3File(JsonData, params = {}) {
  // get values from params
  const S3OutputBucket = params.S3OutputBucket
  const S3OutputKey = params.S3OutputKey
  const AppendDateTimeToFileName = params.AppendDateTimeToFileName || true
  // !_.isUndefined(params.AppendDateTimeToFileName) && _.isBoolean(params.AppendDateTimeToFileName)
  //   ? params.AppendDateTimeToFileName
  //   : true
  const DateTimeFormat = params.DateTimeFormat || 'YYYYMMDD_HHmmssSSS'
  const Overwrite = params.Overwrite || 'yes'

  // delegate call
  return SaveStringToS3File({
    S3OutputBucket,
    S3OutputKey,
    StringData: JSON.stringify(JsonData),
    AppendDateTimeToFileName,
    DateTimeFormat,
    Overwrite,
    FileExtension: '.json',
  })
}

export async function SaveStringToS3File(params = {}) {
  const Bucket = params.S3OutputBucket || ''
  const Key = params.S3OutputKey || ''
  const stringData = params.StringData || ''
  const appendDateTime =
    !_.isUndefined(params.AppendDateTimeToFileName) && _.isBoolean(params.AppendDateTimeToFileName)
      ? params.AppendDateTimeToFileName
      : true
  const DateTimeFormat = params.DateTimeFormat || 'YYYYMMDD_HHmmssSSS'
  const Overwrite = params.Overwrite || 'yes'
  const FileExtension = params.FileExtension || ''
  try {
    if (!stringData) {
      throw new Error('No data to save to S3.')
    }

    // validate key
    if (_.trim(Bucket).length <= 0 || _.trim(Key).length <= 0) {
      throw new Error(
        `Either Bucket ${Bucket} or Key: ${Key} is empty. Need Bucket and Key to save file.`
      )
    }
    // get file name
    const filename = getFileName(Key, FileExtension, appendDateTime, DateTimeFormat)
    // Handle blocking overwrite if Overwrite is 'No'
    if (Overwrite.toLowerCase() === 'no') {
      const fileFound = await s3FileExists({
        Bucket,
        Key: filename,
      })

      if (fileFound) {
        throw new Error(
          'File could not be overwritten. If you wish to overwrite this file, set Overwrite to "Yes"'
        )
      }
    }

    await uploadFileToS3({
      Bucket,
      Key: filename,
      Body: stringData,
    })
    return `s3://${Bucket}/${filename}`
  } catch (err) {
    const msg = `Error saving data to s3 Path:${S3FullFilePath}, error: ${err.message}`
    console.log(msg)
    throw new Error(msg)
  }
}

export function getFileName(
  Key,
  FileExtension = '.json',
  AppendDtTm = true,
  DateTimeFormat = 'YYYYMMDD_HHmmssSSS'
) {
  let filename = _.trim(Key)

  // add or replace time stamp to file name
  if (AppendDtTm) {
    const timestamp = moment().format(DateTimeFormat)
    if (Key.includes(DateTimeFormat)) {
      filename = Key.replace(`{${DateTimeFormat}}`, timestamp).replace(DateTimeFormat, timestamp)
    } else {
      const timeRegEx = new RegExp(
        `(.*)(${moment().format('YYYY')})(\\d{2})(\\d{2})(_{1})(\\d{9})(.*)`,
        'g'
      )
      if (!Key.match(timeRegEx)) {
        filename = `${Key}-${timestamp}`
      }
    }
  }

  // add extension
  if (FileExtension && !_.isEmpty(FileExtension) && !filename.includes(FileExtension))
    filename += FileExtension

  // remove repeatative characters
  filename = filename.replace('--', '-').replace('-_', '-')
  return filename
}

export async function copyS3({ SourceFullPath, TargetBucket, TargetKey }) {
  if (_.isUndefined(SourceFullPath) || _.isEmpty(SourceFullPath)) {
    throw new Error(`Invalid Param. SourceFullPath: ${SourceFullPath} is required.`)
  }
  if (_.isUndefined(TargetBucket) || _.isEmpty(TargetBucket)) {
    throw new Error(`Invalid Param. Target Bucket: ${TargetBucket} is required.`)
  }
  // extract path and key
  const { Bucket, Key } = await s3FileParser(SourceFullPath)
  if (_.isUndefined(Bucket) || _.isUndefined(Key)) {
    throw new Error(
      `Invalid Param. SourcefullPath doesnt have bucket/key name. Bucket: ${Bucket}, key: ${Key}`
    )
  }
  // if target key is not provided then
  // set source key as target key
  let target = !_.isUndefined(TargetKey) && !_.isEmpty(TargetKey) ? TargetKey : Key
  const copyResp = await copyS3toS3({
    SourceBucket: Bucket,
    SourceKey: Key,
    TargetBucket,
    TargetKey: target,
  })
  // if copied successfully then return full path of the copied target path
  if (!_.isUndefined(copyResp) && !_.isUndefined(copyResp.ETag)) {
    return `${TargetBucket}/${target}`
  }
  return ''
}

export async function ArchiveS3File({ SourceFullPath, TargetBucket, TargetKey }) {
  if (_.isUndefined(SourceFullPath) || _.isEmpty(SourceFullPath)) {
    throw new Error(`Invalid Param. SourceFullPath: ${SourceFullPath} is required.`)
  }
  if (_.isUndefined(TargetBucket) || _.isEmpty(TargetBucket)) {
    throw new Error(`Invalid Param. Target Bucket: ${TargetBucket} is required.`)
  }
  // extract path and key
  const { Bucket, Key } = await s3FileParser(SourceFullPath)

  if (_.isUndefined(Bucket) || _.isUndefined(Key)) {
    throw new Error(
      `Invalid Param. SourcefullPath doesnt have bucket/key name. Bucket: ${Bucket}, key: ${Key}`
    )
  }
  // get only file name and ignore all subfolders related to pipeline tasks.
  const filename = Key.replace(/\/\d+\//gi, '/')
  // if target key is not provided then
  // set source key as target key
  let target = !_.isUndefined(TargetKey) && !_.isEmpty(TargetKey) ? TargetKey : filename
  const moveResp = await moveS3toS3({
    SourceBucket: Bucket,
    SourceKey: Key,
    TargetBucket,
    TargetKey: target,
  })
  // if copied successfully then return full path of the copied target path
  if (!_.isUndefined(moveResp) && !_.isUndefined(moveResp.ETag)) {
    return `${TargetBucket}/${target}`
  }
  return ''
}

export async function deleteS3({ SourceFullPath }) {
  if (_.isUndefined(SourceFullPath) || _.isEmpty(SourceFullPath)) {
    throw new Error(`Invalid Param. SourceFullPath: ${SourceFullPath} is required.`)
  }
  // extract path and key
  const { Bucket, Key } = await s3FileParser(SourceFullPath)
  if (_.isUndefined(Bucket) || _.isUndefined(Key)) {
    throw new Error(
      `Invalid Param. SourcefullPath doesnt have bucket/key name. Bucket: ${Bucket}, key: ${Key}`
    )
  }
  const delResp = await DeleteFile({
    SourceBucket: Bucket,
    SourceKey: Key,
  })
  // if deleted successfully then return full path of the copied target path
  if (!_.isUndefined(delResp) && !_.isUndefined(delResp.Deleted) && delResp.Deleted === true) {
    return { S3FullPath: `${delResp.Bucket}/${delResp.Key}`, Deleted: true }
  }
  return { S3FullPath: `${Bucket}/${Key}`, Deleted: false }
}
