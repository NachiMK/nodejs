import AWS from 'aws-sdk'

const awsS3 = new AWS.S3({ region: 'us-west-2' })
const { Pool } = require('pg')
const copyFrom = require('pg-copy-streams').from

export const UploadS3FileToDB = async (params = {}) => {
  const retResp = {
    status: 'processing',
    CountBeforeUpload: -1,
    CountAfterUpload: -1,
    error: undefined,
  }
  const { TableName, S3FilePath, UploadOptions, ConnectionString } = params

  ValidateParams(params)
  // upload file.
  try {
    const s3params = s3FileParser(S3FilePath)
    console.log(`About to copy, TableName: ${TableName} S3FilePath: ${S3FilePath}`)
    console.log(`ConnectionString Defined? ${ConnectionString !== 'undefined'}`)

    const pool = new Pool({ connectionString: ConnectionString })
    const client = await pool.connect()
    retResp.CountBeforeUpload = await getRowCnt(client, TableName)
    try {
      // get query to upload
      const queryTxt = getQueryText(TableName, UploadOptions)
      // setup upload
      const res = await client.query(copyFrom(queryTxt))
      console.log(
        `Created pg Client & Query.About to pipe data. ${JSON.stringify(s3params, null, 2)}`
      )
      // stream data to table
      await awsS3
        .getObject(s3params)
        .createReadStream()
        .pipe(res)
      retResp.status = 'success'
      // get count after upload
      retResp.CountAfterUpload = await getRowCnt(client, TableName)
    } catch (err1) {
      console.log(`Error in connecting to DB and streaming: ${err1.message}`)
      retResp.status = 'error'
      throw new Error(`Error in connecting to DB and streaming: ${err1.message}`)
    } finally {
      client.release()
    }
    return retResp
  } catch (err) {
    console.log('Error uploading file or getting row counts.', err.message)
    retResp.status = 'error'
    throw new Error(`Error in UploadS3FileToDB, ${err.message}`)
  }
  }

const getRowCnt = async (psqlClient, tableName) => {
  let rowCntResp
  let rowCnt
  if (psqlClient && tableName) {
    try {
      rowCntResp = await psqlClient.query(`SELECT COUNT(*) as Cnt FROM ${tableName};`)
      if (rowCntResp && rowCntResp.rows && rowCntResp.rows.length > 0) {
        rowCnt = rowCntResp.rows[0].cnt
      }
    } catch (err) {
      throw new Error(`Error getting row count from table: ${tableName}, Error: ${err.message}`)
    }
    if (rowCnt >= 0) {
      return rowCnt
    } else {
      throw new Error(`Getting Row count returned empty results. Check if Table exists, 
      Row Count Response: ${JSON.stringify(rowCntResp, null, 2)}`)
    }
  } else {
    throw new Error(
      `Cannot Get Row Count, Either: psqClient is undefined or tableName: ${tableName} is undefined.`
    )
  }
}

const s3FileParser = (filepath) => {
  const [source, empty, Bucket, ...file] = filepath.split('/')
  console.log(`filePath Parsed: source:${source}, empty: ${empty}, Bucket: ${Bucket}, File:${file}`)
  return {
    Bucket,
    Key: file.join('/'),
  }
}

function getQueryText(TableName, UploadOptions) {
  let retVal = `COPY ${TableName} FROM STDIN ${getOptions(UploadOptions)}`
  console.log('Query Text to import data:', retVal)
  return retVal
}

function getOptions(UploadOptions) {
  try {
    if (UploadOptions && UploadOptions.FileType) {
      return `WITH (
        ${getFormat(UploadOptions.FileType)}
        ${getDelimiter(UploadOptions)}
        ${getNullChar(UploadOptions)}
        ${getHeader(UploadOptions)}
        ${getQuote(UploadOptions)})`
    }
    return getDefaultOptions()
  } catch (err) {
    throw new Error(
      `Unknow Upload Options provided. ${JSON.stringify(UploadOptions, null, 2)}. Error:${
        err.message
      }`
    )
  }
}

function getFormat(fileType) {
  console.log('Format type:', fileType)
  if (fileType) {
    return ` FORMAT ${getFileType(fileType)}`
  }
  return ' FORMAT csv'
}

function getDelimiter(uploadOptions) {
  if (uploadOptions) {
    switch (getFileType(uploadOptions.FileType)) {
      case 'csv':
        return ",DELIMITER ','"
      case 'text':
        if (uploadOptions && uploadOptions.Delimiter && uploadOptions.Delimiter.length > 0) {
          return `,DELIMITER '${uploadOptions.Delimiter[0]}'`
        }
        // by default it is TAB that is considered as delimiter.
        return ''
      default:
        return ''
    }
  }
}

function getHeader(uploadOptions) {
  if (uploadOptions) {
    let headerFlag =
      uploadOptions.HasHeader && uploadOptions.HasHeader.toLowerCase() === 'true' ? 'true' : 'false'
    if (getFileType(uploadOptions.FileType) === 'csv') {
      return `,HEADER ${headerFlag}`
    }
  }
  return ''
}

function getQuote(uploadOptions) {
  if (uploadOptions) {
    let quotechar =
      uploadOptions.QuoteChar && uploadOptions.QuoteChar.length > 0
        ? uploadOptions.QuoteChar[0]
        : '"'
    if (getFileType(uploadOptions.FileType) === 'csv') {
      return `,QUOTE '${quotechar}'`
    }
  }
  return ''
}

function getNullChar(uploadOptions) {
  if (uploadOptions) {
    let nullchar = uploadOptions.NullString || ''
    if (getFileType(uploadOptions.FileType) !== 'binary') {
      return `,NULL '${nullchar}'`
    }
  }
  return ''
}

function getDefaultOptions() {
  return "WITH (FORMAT csv,HEADER true,NULL '',QUOTE '\"')"
}

function getFileType(fileType) {
  switch (fileType) {
    case 'CSV':
    case 'csv':
      return 'csv'
    case 'BINARY':
    case 'binary':
      return 'binary'
    case 'TEXT':
    case 'txt':
    case 'TXT':
    case 'text':
      return 'text'
    default:
      throw new Error('Unknown File format')
  }
}

const ValidateParams = (params = {}) => {
  if (!params) {
    throw new Error(
      `Invalid Parameter for uploading plans and rates.Params: ${JSON.stringify(params, null, 2)}`
    )
  } else {
    if (!params.TableName) {
      throw new Error(
        `Invalid Parameter: Table Name is required to upload file. Table: ${params.BatchName}`
      )
    } else if (!params.S3FilePath) {
      throw new Error(
        `Invalid Parameter: S3FilePath is required. S3FilePath : ${params.S3FilePath}`
      )
    } else if (!params.ConnectionString) {
      throw new Error(
        `Invalid Parameter: Connection Stirng is required. Connection String: ${
          params.ConnectionString
        }`
      )
    }
  }
}
