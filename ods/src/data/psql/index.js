import pg from 'pg';
// the import order matters, we need pg types set first.
import Knex from 'knex';
import knexDialect from 'knex/lib/dialects/postgres';

require('dotenv').config();

pg.types.setTypeParser(20, 'text', parseInt);
pg.types.setTypeParser(1700, parseFloat);

const {
  STAGE,
} = process.env;

export const executeQueryRS = async (params = {}) => {
  console.warn('Executing query..');
  const ret = {
    rows: [],
    rowCount: -1,
    error: '',
    completed: false,
  };

  const {
    Query,
    DBName,
  } = params;

  // may throw an error
  IsValidParams(params, true);

  try {
    const localKnex = knex(DBName);
    let logresp = await logSQLCommand(params, 'executeQueryRS');
    const id = logresp.scalarValue;
    const knexResp = await localKnex.raw(Query);
    if ((knexResp) && (knexResp.rows)) {
      ret.rows = knexResp.rows;
      ret.completed = true;
      ret.rowCount = knexResp.rowCount;
    }
    logresp = await updateCommandLogEndTime(await getCommandLogID(id));
  } catch (err) {
    ret.rows = [];
    ret.completed = false;
    ret.rowCount = -1;
    ret.error = err;
  }
  return ret;
};

export const executeScalar = async (params = {}) => {
  const retSingleValue = {
    scalarValue: '',
    completed: false,
    error: undefined,
  };

  const {
    Query,
    DBName,
  } = params;

  let ret;

  // may throw an error
  IsValidParams(params, true);

  try {
    let logresp = await logSQLCommand(params, 'executeScalar');
    const id = logresp.scalarValue;
    const localKnex = knex(DBName);
    ret = await localKnex.raw(Query);
    if (ret) {
      if (ret.rows && (ret.rows.length > 0)) {
        const value = Object.values(ret.rows[0])[0];
        retSingleValue.scalarValue = value;
        retSingleValue.completed = true;
      }
      logresp = await updateCommandLogEndTime(await getCommandLogID(id));
    }
  } catch (err) {
    ret = {
      scalarValue: undefined,
      error: err,
      completed: false,
    };
  }
  return retSingleValue;
};

export const executeCommand = async (params = {}) => {
  const ret = {
    error: '',
    completed: false,
  };

  const {
    Query,
    DBName,
  } = params;
  // may throw an error
  IsValidParams(params, true);
  let logresp;
  try {
    logresp = await logSQLCommand(params, 'executeCommand');
    const id = logresp.scalarValue;
    const localKnex = knex(DBName);
    await localKnex.raw(Query);
    ret.completed = true;
    logresp = await updateCommandLogEndTime(await getCommandLogID(id));
  } catch (err) {
    ret.error = err;
    ret.completed = false;
  }
  return ret;
};

export const logSQLCommand = async (params = {}, commandType = 'UNKNOWN') => {
  const retSingleValue = {
    scalarValue: '',
    completed: false,
    error: undefined,
  };

  const dbName = process.env.log_dbname || 'ODSLog';
  const {
    Query,
    DBName,
    BatchKey,
  } = params;

  try {
    const localKnex = knex(dbName);
    const resp = await localKnex.raw('SELECT udf_insert_commandlog(?,?,?,?)', [BatchKey, DBName, Query, commandType]);
    if (resp) {
      if (resp.rows && (resp.rows.length > 0)) {
        const value = Object.values(resp.rows[0])[0];
        retSingleValue.scalarValue = value;
        retSingleValue.completed = true;
      }
    }
  } catch (err) {
    retSingleValue.error = err;
    retSingleValue.completed = false;
  }
  return retSingleValue;
};

export const updateCommandLogEndTime = async (commandLogID) => {
  const ret = {
    completed: false,
    error: undefined,
  };

  // if invalid return without updating.
  if (commandLogID < 0) {
    return ret;
  }

  const dbName = process.env.log_dbname || 'ODSLog';
  try {
    const localKnex = knex(dbName);
    const resp = await localKnex.raw('SELECT udf_update_commandlog_endtime(?)', commandLogID);
    ret.completed = (true && resp);
  } catch (err) {
    ret.error = err;
    ret.completed = false;
  }
  return ret;
};

function getConnectionString(dbName, stage) {
  const key = `${stage.toUpperCase()}_${dbName.toUpperCase()}'_PG'`;
  const idx = Object.keys(process.env).indexOf(key);
  let retVal;
  if (idx >= 0) {
    retVal = process.env[key];
  } else {
    console.warn(`Invalid DB Name passed. DBName: ${dbName}, Key: ${key}, Stage: ${stage}`);
    throw new RangeError(`Connection string for database: ${dbName} is not found in environment variables or .env file.`);
  }
  return retVal;
}

function knex(dbName) {
  const cs = getConnectionString(dbName, STAGE);
  const knexPgClient = Knex({
    client: 'pg',
    connection: cs,
    debug: STAGE !== 'prod',
  });
  knexPgClient.client = knexDialect;
  const retKnex = knexPgClient;
  return retKnex;
}

function IsValidQuery(query) {
  if ((query) && (typeof query === 'string')) {
    if (query.length > 0) {
      return true;
    }
  }
  return false;
}

function IsValidBatchKeyName(batchName) {
  if (batchName) {
    return true;
  }
  return false;
}

function IsValidDBName(dbName) {
  if (dbName) {
    return true;
  }
  return false;
}

function IsValidParams(params = {}, ThrowErrorIfInvalid = true) {
  const {
    Query,
    DBName,
    BatchKey,
  } = params;
  let HasErrors = false;
  let ErrorMsg = '';
  if (!IsValidQuery(Query)) {
    ErrorMsg = `${ErrorMsg} Invalid Query. It cannot be null or empty.`;
    HasErrors = true;
  }

  if (!IsValidBatchKeyName(BatchKey)) {
    ErrorMsg = `${ErrorMsg} Invalid BatchKey, It cannot be null or empty.`;
    HasErrors = true;
  }

  if (!IsValidDBName(DBName)) {
    ErrorMsg = `${ErrorMsg} DBName cannot be null or empty`;
    HasErrors = true;
  }

  if (HasErrors && ThrowErrorIfInvalid) {
    ErrorMsg += `Query: {${Query}}, Batch: {${BatchKey}}, DBName :{${DBName}}`;
    throw new Error(ErrorMsg);
  }

  return HasErrors;
}

function getCommandLogID(commandLogID) {
  let intLogID = -1;
  if (commandLogID) {
    if ((commandLogID) && (!isNaN(parseInt(commandLogID, 10)))) {
      intLogID = parseInt(commandLogID, 10);
    }
  }
  return intLogID;
}
