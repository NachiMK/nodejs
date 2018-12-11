import pg from 'pg'
import crypto from 'crypto'
import moment from 'moment'
// the import order matters, we need pg types set first.
import Knex from 'knex'
import isEmpty from 'lodash/isEmpty'
import isUndefined from 'lodash/isUndefined'
import knexDialect from 'knex/lib/dialects/postgres'
import ODSLogger from '../../modules/log/ODSLogger'

require('dotenv').config()

pg.types.setTypeParser(20, 'text', parseInt)
pg.types.setTypeParser(1700, parseFloat)

const { STAGE } = process.env

export const executeQueryRS = async (params = {}) => {
  ODSLogger.log('debug', 'Executing query RS..')
  const ret = {
    rows: [],
    rowCount: -1,
    error: {},
    completed: false,
  }

  const { Query, DBName } = params
  const dbConnString = params.ConnectionString || ''
  // may throw an error
  IsValidParams(params, true)
  const localKnex = IsValidConnectionString(dbConnString)
    ? knexByConnectionString(dbConnString)
    : knex(DBName)
  try {
    let logresp = await logSQLCommand(params, 'executeQueryRS')
    ODSLogger.log('debug', 'About to run query:%j', params)
    const id = logresp.scalarValue
    const knexResp = await localKnex.raw(QuoteSQL(Query))
    if (knexResp && knexResp.rowCount >= 0) {
      ret.rows = knexResp.rows
      ret.completed = true
      ret.rowCount = knexResp.rowCount
    }
    ODSLogger.log('debug', 'Completed running query:', params)
    logresp = await updateCommandLogEndTime(await getCommandLogID(id))
  } catch (err) {
    ret.rows = []
    ret.completed = false
    ret.rowCount = -1
    ret.error = err
    ODSLogger.log('warn', 'Error running ExecuteQueryRS:%j', err)
  }
  localKnex.destroy()
  return ret
}

export const executeScalar = async (params = {}) => {
  const retSingleValue = {
    scalarValue: '',
    completed: false,
    error: undefined,
  }

  const { Query, DBName } = params
  const dbConnString = params.ConnectionString || ''
  // may throw an error
  IsValidParams(params, true)
  const localKnex = IsValidConnectionString(dbConnString)
    ? knexByConnectionString(dbConnString)
    : knex(DBName)

  try {
    let logresp = await logSQLCommand(params, 'executeScalar')
    const id = logresp.scalarValue
    ODSLogger.log('debug', 'About to run scalar query:%j', params)
    const resExeScalar = await localKnex.raw(QuoteSQL(Query))
    ODSLogger.log('debug', 'scalar query Response:%j', resExeScalar)
    if (resExeScalar) {
      if (resExeScalar.rows && resExeScalar.rows.length > 0) {
        const value = Object.values(resExeScalar.rows[0])[0]
        retSingleValue.scalarValue = value
        retSingleValue.completed = true
      }
    }
    logresp = await updateCommandLogEndTime(await getCommandLogID(id))
  } catch (err) {
    retSingleValue.scalarValue = undefined
    retSingleValue.completed = false
    retSingleValue.error = err
    ODSLogger.log('warn', 'Error running ExecuteScalar:%j', err)
  }
  localKnex.destroy()
  return retSingleValue
}

export const executeCommand = async (params = {}) => {
  const ret = {
    error: undefined,
    completed: false,
  }

  const { Query, DBName } = params
  const dbConnString = params.ConnectionString || ''
  // may throw an error
  IsValidParams(params, true)
  const localKnex = IsValidConnectionString(dbConnString)
    ? knexByConnectionString(dbConnString)
    : knex(DBName)
  let logresp
  try {
    logresp = await logSQLCommand(params, 'executeCommand')
    const id = logresp.scalarValue
    ODSLogger.log('debug', 'About to run Execute command:%j', params)
    logresp = await localKnex.raw(QuoteSQL(Query))
    ret.completed = true && !isUndefined(logresp)
    logresp = await updateCommandLogEndTime(await getCommandLogID(id))
  } catch (err) {
    ret.error = err
    ret.completed = false
    ODSLogger.log('warn', 'Error running ExecuteCommand:%j', err)
  }
  localKnex.destroy()
  return ret
}

export const logSQLCommand = async (params = {}, commandType = 'UNKNOWN') => {
  const retSingleValue = {
    scalarValue: '',
    completed: false,
    error: undefined,
  }

  const odsLogDbName = process.env.log_dbname || 'ODSLog'
  const { Query, DBName } = params
  const BatchKey = params.BatchKey || getDefaultBatchKey(Query)

  const localKnex = knex(odsLogDbName)
  try {
    ODSLogger.log('debug', 'About to Log Query details: %j', Query)
    const resp1 = await localKnex.raw('SELECT udf_insert_commandlog(?,?,?,?)', [
      BatchKey,
      DBName || '',
      Query,
      commandType,
    ])
    if (resp1) {
      if (resp1.rows && resp1.rows.length > 0) {
        const value = Object.values(resp1.rows[0])[0]
        retSingleValue.scalarValue = value
        retSingleValue.completed = true
      }
    }
  } catch (err) {
    retSingleValue.error = err
    retSingleValue.completed = false
    ODSLogger.log('warn', 'Error logging Query details: %j', err)
  }
  localKnex.destroy()
  return retSingleValue
}

export const updateCommandLogEndTime = async (commandLogID) => {
  const ret = {
    completed: false,
    error: undefined,
  }

  // if invalid return without updating.
  if (commandLogID < 0) {
    return ret
  }

  const odsLogDBName = process.env.log_dbname || 'ODSLog'
  const localKnex = knex(odsLogDBName)
  try {
    const resp = await localKnex.raw('SELECT udf_update_commandlog_endtime(?)', commandLogID)
    ret.completed = true && resp
  } catch (err) {
    ret.error = err
    ret.completed = false
    ODSLogger.log('warn', 'Error updating end time query:%j', err)
  }
  localKnex.destroy()
  return ret
}

export function knexNoDB() {
  const knexPgClient = Knex({
    client: 'pg',
  })
  knexPgClient.client = knexDialect
  const retKnex = knexPgClient
  return retKnex
}

export function getConnectionString(dbName, stage) {
  const key = `${stage}_${dbName}_PG`.toUpperCase()
  const idx = Object.keys(process.env).indexOf(key)
  let retVal
  if (idx >= 0) {
    retVal = process.env[key]
  } else {
    ODSLogger.log(
      'error',
      `Invalid DB Name passed. DBName: ${dbName}, Key: ${key}, Stage: ${stage}`
    )
    throw new RangeError(
      `Connection string for database: ${dbName} is not found in environment variables or .env file.`
    )
  }
  return retVal
}

function knex(dbName) {
  const cs = getConnectionString(dbName, STAGE)
  const knexPgClient = Knex({
    client: 'pg',
    connection: cs,
    debug: STAGE !== 'prod',
    pool: { min: 0, max: 1 },
  })
  knexPgClient.client = knexDialect
  const retKnex = knexPgClient
  return retKnex
}

export function knexByConnectionString(connectionString) {
  const cs = connectionString
  const knexPgClient = Knex({
    client: 'pg',
    connection: cs,
    debug: STAGE !== 'prod',
    pool: { min: 0, max: 1 },
  })
  knexPgClient.client = knexDialect
  const retKnex = knexPgClient
  return retKnex
}

function IsValidQuery(query) {
  if (query && typeof query === 'string') {
    if (query.length > 0) {
      return true
    }
  }
  return false
}

function IsValidConnectionString(connString) {
  if (connString && !isEmpty(connString)) {
    return true
  }
  return false
}

function IsValidDBName(dbName) {
  if (dbName && !isEmpty(dbName)) {
    return true
  }
  return false
}

function IsValidParams(params = {}, ThrowErrorIfInvalid = true) {
  const { Query, DBName, BatchKey } = params
  let HasErrors = false
  let ErrorMsg = ''
  if (!IsValidQuery(Query)) {
    ErrorMsg = `${ErrorMsg} Invalid Query. It cannot be null or empty.`
    HasErrors = true
  }

  if (!IsValidConnectionString(params.ConnectionString) && !IsValidDBName(DBName)) {
    ErrorMsg = `${ErrorMsg} DBName or ConnectionString is required, Both cannot be empty.`
    HasErrors = true
  }

  if (HasErrors && ThrowErrorIfInvalid) {
    ErrorMsg += `Query: {${Query}}, Batch: {${BatchKey}}, DBName :{${DBName}}`
    throw new Error(ErrorMsg)
  }

  return HasErrors
}

function getCommandLogID(commandLogID) {
  let intLogID = -1
  if (commandLogID) {
    if (commandLogID && !isNaN(parseInt(commandLogID, 10))) {
      intLogID = parseInt(commandLogID, 10)
    }
  }
  return intLogID
}

function getDefaultBatchKey(Query) {
  const hash = crypto
    .createHash('md5')
    .update(Query)
    .digest('hex')
  return `${hash}_${moment().format('YYMMDD_HHmmssSSS')}`
}

function QuoteSQL(Query) {
  if (Query && typeof Query === 'string') {
    return Query.replace('?', '\\?')
  }
  return Query
}

// function getTestDataPipeLineRetVal() {
//   const ret = {
//     rows: [
//       {
//         DataFilePrefix: 'dynamodb/clients/1-clients-test-Data-',
//         S3DataFileBucketName: 'dev-ods-data',
//         DataPipeLineTaskQueueId: 1,
//       },
//     ],
//     rowCount: 1,
//     error: '',
//     completed: true,
//   };
//   return ret;
// }
