import AWS from 'aws-sdk'

const awsS3 = new AWS.S3({
  region: 'us-west-2',
  endpoint: 'https://s3.us-west-2.amazonaws.com',
})

export const s3BucketFactory = (Bucket) => (Key, options) =>
  awsS3
    .getObject({
      Bucket,
      Key,
      ...options,
    })
    .promise()

export const uploadFileToS3 = async ({ Bucket, Key, Body }) => {
  try {
    // console.log(`Bucket:${Bucket}, key:${Key}, Body:${Body}`);
    const retVal = await awsS3
      .putObject({
        Bucket,
        Key,
        Body,
      })
      .promise()
    console.log('retVal:', JSON.stringify(retVal, null, 2))
    return retVal
  } catch (err) {
    const error = new Error(err.message)
    error.status = err.status
    console.error('error uploading to S3:', JSON.stringify(err, null, 2))
    throw error
  }
}

export const s3FileParser = (filepath) => {
  const [source, empty, Bucket, ...file] = filepath.split('/')
  console.log(`filePath Parsed: source:${source}, empty: ${empty}, Bucket: ${Bucket}, File:${file}`)
  return {
    Bucket,
    Key: file.join('/'),
  }
}

export const getS3JSON = async ({ Bucket, Key }) => {
  try {
    const file = await s3BucketFactory(Bucket)(Key)
    return JSON.parse(file.Body)
  } catch (e) {
    throw e
  }
}

export const s3FileExists = async ({ Bucket, Key }) => {
  try {
    const findFile = await getS3JSON({
      Bucket,
      Key,
    })

    return true && typeof findFile === 'object'
  } catch (e) {
    if (e.code === 'NoSuchKey') {
      return false
    }

    throw e
  }
}
