import pg from 'pg';
// the import order matters, we need pg types set first.
import Knex from 'knex';
import knexDialect from 'knex/lib/dialects/postgres';
require('dotenv').config();

pg.types.setTypeParser(20, 'text', parseInt)
pg.types.setTypeParser(1700, parseFloat)

const {
  STAGE,
} = process.env

export const executeQueryRS = async (params = {}) => {
  console.warn("Executing query..");
  let ret = {
    "rows": [],
    "rowCount": -1,
    "error": "",
    "completed": false,
  };
  
  const {
    Query,
    DBName,
    BatchKey
  } = params;

  // may throw an error
  IsValidParams(params, true);

  try {
    let localKnex = knex(DBName);
    let logresp = await logSQLCommand(params, "executeQueryRS");
    let knexResp = await localKnex.raw(Query);
    if ((knexResp) && (knexResp.hasOwnProperty("rows"))) {
      ret.rows = knexResp.rows;
      ret.completed = true;
      ret.rowCount = knexResp.rowCount;
    }
    logresp = updateCommandLogEndTime(getCommandLogID(logresp));
  }
  catch (err) {
    ret.rows = [];
    ret.completed = false;
    ret.rowCount = -1;
    ret.error = err;
  }
  return ret;
}

export const executeScalar = async (params={}) => {
  let retSingleValue = {
    "scalarValue": "",
    "completed": false,
    "error": undefined,
  };
  
  const {
    Query,
    DBName,
    BatchKey
  } = params;
  // may throw an error
  IsValidParams(params, true);

  try {
    let logresp = await logSQLCommand(params, "executeScalar");
    let localKnex = knex(dbName);
    let ret = await localKnex.raw(query);
    if (ret) {
      if (ret.hasOwnProperty("rows") && (ret.rows.length > 0)) {
        let value = Object.values(ret.rows[0])[0];
        retSingleValue.scalarValue = value;
        retSingleValue.completed = true;
      }
      logresp = updateCommandLogEndTime(getCommandLogID(logresp));
    }
  }
  catch (err) {
    ret = {
      "scalarValue": undefined,
      "error": err,
      "completed": false,
    };
  }
  return retSingleValue;
}

export const executeCommand = async (params={}) => {
  let ret = {
    "error": "",
    "completed": false,
  };
  
  const {
    Query,
    DBName,
    BatchKey
  } = params;
  // may throw an error
  IsValidParams(params, true);

  try {
    let logresp = await logSQLCommand(params, "executeCommand");
    let localKnex = knex(dbName);
    await localKnex.raw(query);
    ret.completed = true;
    logresp = updateCommandLogEndTime(getCommandLogID(logresp));
  }
  catch (err) {
    ret.error = err;
    ret.completed = false;
  }
  return ret;
}

export const logSQLCommand = async (params = {}, commandType = "UNKNOWN") => {
  let retSingleValue = {
    "scalarValue": "",
    "completed": false,
    "error": undefined,
  };

  let dbName = process.env.log_dbname || "ODSLog";
  const {
    Query,
    DBName,
    BatchKey
  } = params;

  try {
    let localKnex = knex(dbName);
    let resp = await localKnex.raw('SELECT udf_insert_commandlog(?,?,?,?)', [BatchKey, dbName, Query, commandType]);
    if (resp) {
      if (resp.hasOwnProperty("rows") && (resp.rows.length > 0)) {
        let value = Object.values(resp.rows[0])[0];
        retSingleValue.scalarValue = value;
        retSingleValue.completed = true;
      }
    }
  }
  catch (err) {
    retSingleValue.error = err;
    retSingleValue.completed = false;
  }
  return retSingleValue;

}

export const updateCommandLogEndTime = async (commandLogID) => {
  let ret = {
    "completed": false,
    "error": undefined,
  };

  // if invalid return without updating.
  if (commandLogID < 0){
    return ret;
  }

  let dbName = process.env.log_dbname || "ODSLog";
  try {
    let localKnex = knex(dbName);
    let resp = await localKnex.raw('SELECT udf_update_commandlog_endtime(?)', commandLogID);
    ret.completed = true;
  }
  catch (err) {
    ret.error = err;
    ret.completed = false;
  }
  return ret;
}

function getConnectionString(dbName, stage) {
  let key = stage.toUpperCase() + '_' + dbName.toUpperCase() + '_pg'.toUpperCase();
  let idx = Object.keys(process.env).indexOf(key);
  if (idx >= 0) {
    return process.env[key];
  }
  else {
    console.warn(`Invalid DB Name passed. DBName: ${dbName}, Key: ${key}, Stage: ${stage}`);
    throw new RangeError(`Connection string for database: ${dbName} is not found in environment variables or .env file.`);
  }
  return;
}

function knex(dbName) {
  let cs = getConnectionString(dbName, STAGE);
  const knexPgClient = Knex({
    client: 'pg',
    connection: cs,
    debug: STAGE !== 'prod',
  })
  knexPgClient.client = knexDialect
  const retKnex = knexPgClient;
  return retKnex;
}

function IsValidQuery(query){
  if ((query) && (typeof query === "string")){
    if (query.length > 0){
      return true;
    }
  }
  return false;
}

function IsValidBatchKeyName(batchName){
  if (batchName){
    return true;
  }
  return false;
}

function IsValidDBName(dbName){
  if (dbName){
    return true;
  }
  return false;
}

function IsValidParams(params={}, ThrowErrorIfInvalid = true){
  const {
    Query,
    DBName,
    BatchKey
  } = params;
  let HasErrors = false;
  let ErrorMsg = "";
  if (!IsValidQuery(Query)){
      ErrorMsg = ErrorMsg + "Invalid Query. It cannot be null or empty.";
      HasErrors = true;
  }

  if (!IsValidBatchKeyName(BatchKey)){
    ErrorMsg = ErrorMsg + "Invalid BatchKey, It cannot be null or empty.";
    HasErrors = true;
  }

  if (!IsValidDBName(DBName)){
    ErrorMsg = ErrorMsg + "DBName cannot be null or empty";
    HasErrors = true;
  }

  if (HasErrors && ThrowErrorIfInvalid){
    ErrorMsg = ErrorMsg + `Query: {${Query}}, Batch: {${BatchKey}}, DBName :{${DBName}}`;
    throw new Error(ErrorMsg);
  }

  return HasErrors;
}

function getCommandLogID(dbResp){
  let intLogID = -1;
  if (dbResp){
    //
    const {
      scalarValue,
      completed,
    } = dbResp;

    if ((scalarValue) && (parseInt(scalarValue) !== NaN)){
      intLogID = parseInt(scalarValue);
    }
  }
  return intLogID;
}