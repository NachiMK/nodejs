import _ from 'lodash';
import moment from 'moment';
import { s3FileParser, uploadFileToS3, s3BucketFactory, s3FileExists } from '../s3/index';

export const GetJSONFromS3Path = async (s3FilePath) => {
  try {
    const {
      Bucket,
      Key,
    } = await s3FileParser(s3FilePath);

    if ((_.trim(Bucket).length <= 0) || (_.trim(Key).length <= 0)) {
      throw new Error(`Either Bucket ${Bucket} or Key: ${Key} is empty. Need Bucket and Key to Load file.`);
    }

    const file = await s3BucketFactory(Bucket)(Key);
    return JSON.parse(file.Body);
  } catch (e) {
    const msg = `Error loading data from s3 Path:${s3FilePath}, error: ${e.message}`;
    console.log(msg);
    throw new Error(msg);
  }
};

export async function SaveJsonToS3File(S3FullFilePath, JsonData, DateTimeFormat = 'YYYYMMDD_HHmmssSSS', Overwrite = 'yes') {
  try {
    if (!JsonData) {
      throw new Error('No data to save for file in Filling Missing Values.');
    }
    // Set up save file parameters
    const { Bucket, Key } = s3FileParser(S3FullFilePath);
    // validate key
    if ((_.trim(Bucket).length <= 0) || (_.trim(Key).length <= 0)) {
      throw new Error(`Either Bucket ${Bucket} or Key: ${Key} is empty. Need Bucket and Key to save file.`);
    }
    // get file name
    const filename = getFileName(Key, DateTimeFormat);
    // Handle blocking overwrite if Overwrite is 'No'
    if (Overwrite.toLowerCase() === 'no') {
      const fileFound = await s3FileExists({
        Bucket,
        Key: filename,
      });

      if (fileFound) {
        throw new Error('File could not be overwritten. If you wish to overwrite this file, set Overwrite to "Yes"');
      }
    }

    await uploadFileToS3({
      Bucket,
      Key: filename,
      Body: JSON.stringify(JsonData),
    });
    return `s3://${Bucket}/${filename}`;
  } catch (err) {
    const msg = `Error saving data to s3 Path:${S3FullFilePath}, error: ${err.message}`;
    console.log(msg);
    throw new Error(msg);
  }
}

function getFileName(Key, DateTimeFormat = 'YYYYMMDD_HHmmssSSS') {
  let filename = _.trim(Key);

  // add or replace time stamp to file name
  const timestamp = moment().format(DateTimeFormat);
  if (Key.includes(DateTimeFormat)) {
    filename = Key.replace(`{${DateTimeFormat}}`, timestamp).replace(DateTimeFormat, timestamp);
  } else {
    filename = `${Key}-${timestamp}`;
  }

  // add extension
  if (!filename.includes('.json')) filename += '.json';

  // remove repeatative characters
  filename = filename.replace('--', '-').replace('-_', '-');
  return filename;
}
