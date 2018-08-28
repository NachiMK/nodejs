import _ from 'lodash'
import moment from 'moment'
import { s3FileParser, uploadFileToS3, s3BucketFactory, s3FileExists } from '../s3/index'

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

export async function SaveJsonToS3File(
  S3FullFilePath,
  JsonData,
  DateTimeFormat = 'YYYYMMDD_HHmmssSSS',
  Overwrite = 'yes'
) {
  return SaveStringToS3File({
    S3FullFilePath,
    StringData: JSON.stringify(JsonData),
    DateTimeFormat,
    Overwrite,
    FileExtension: '.json',
  })
}

export async function SaveStringToS3File(params = {}) {
  const S3FullFilePath = params.S3FullFilePath || ''
  const stringData = params.StringData || ''
  const appendDateTime =
    !_.isUndefined(params.AppendDateTimeToFileName) && _.isBoolean(params.AppendDateTimeToFileName)
      ? params.AppendDateTimeToFileName
      : true
  const DateTimeFormat = params.DateTimeFormat || 'YYYYMMDD_HHmmssSSS'
  const Overwrite = params.Overwrite || 'yes'
  const FileExtension = params.FileExtension || '.json'
  try {
    if (!stringData) {
      throw new Error('No data to save to S3.')
    }
    // Set up save file parameters
    const { Bucket, Key } = s3FileParser(S3FullFilePath)
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
      filename = `${Key}-${timestamp}`
    }
  }

  // add extension
  if (FileExtension && !_.isEmpty(FileExtension) && !filename.includes(FileExtension))
    filename += FileExtension

  // remove repeatative characters
  filename = filename.replace('--', '-').replace('-_', '-')
  return filename
}
