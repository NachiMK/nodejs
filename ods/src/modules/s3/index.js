import AWS from 'aws-sdk';

export const s3 = new AWS.S3({ region: 'us-west-2' });

export const s3BucketFactory = Bucket => (Key, options) =>
  s3.getObject({
    Bucket,
    Key,
    ...options,
  }).promise();

export const uploadFileToS3 = async ({
  Bucket,
  Key,
  Body,
}) => {
  try {
    return await s3.putObject({
      Bucket,
      Key,
      Body,
    }).promise();
  } catch (err) {
    const error = new Error(err.message);
    error.status = err.status;

    throw error;
  }
};

export const s3FileParser = (filepath) => {
  const [source, empty, Bucket, ...file] = filepath.split('/');
  console.log(source, empty, Bucket, file);
  return {
    Bucket,
    Key: file.join('/'),
  };
};

export const getS3JSON = async ({
  Bucket,
  Key,
}) => {
  try {
    const file = await s3BucketFactory(Bucket)(Key);
    return JSON.parse(file.Body);
  } catch (e) {
    throw e;
  }
};

export const s3FileExists = async ({
  Bucket,
  Key,
}) => {
  try {
    const findFile = await getS3JSON({
      Bucket,
      Key,
    });

    return true && findFile;
  } catch (e) {
    if (e.code === 'NoSuchKey') {
      return false;
    }

    throw e;
  }
};
