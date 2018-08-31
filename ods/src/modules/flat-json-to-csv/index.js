export const FlatJsonToCSV = async (params = {}) => {
  const resp = {
    status: {
      message: 'processing',
    },
    error: undefined,
    S3CSVJsonFiles: undefined,
  }
  console.log(`Parameters for FlatJsonToCSV: ${JSON.stringify(params)}`)

  ValidateParams(params)

  try {
    // do something
  } catch (err) {
    resp.status.message = 'error'
    resp.error = new Error(`Error converting Flat Json Data to CSV, ${err.message}`)
  }
  // return
  return resp
}

function ValidateParams(params = {}) {
  if (!params.S3DataFile) {
    throw new Error('Invalid Param: S3DataFile is required for FlatJsonToCSV')
  }
  if (!params.S3SchemaFile) {
    throw new Error('Invalid Param: S3SchemaFile is required for FlatJsonToCSV')
  }
  if (!params.S3OutputBucket) {
    throw new Error('Invalid Param: S3OutputBucket is required for FlatJsonToCSV')
  }
  if (!params.S3CSVFilePrefix) {
    throw new Error('Invalid Param: S3CSVFilePrefix is required for FlatJsonToCSV')
  }
  if (!params.TableName) {
    throw new Error('Invalid Param: TableName is required for FlatJsonToCSV')
  }
  if (!params.BatchId) {
    throw new Error('Invalid Param: BatchId is required for FlatJsonToCSV')
  }
}
