import { getConnectionString, executeScalar } from '../../data/psql'
import _ from 'lodash'
import { format as _format, transports as _transports, createLogger } from 'winston'

class QueueInitialImport {
  logger = createLogger({
    format: _format.combine(
      _format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss',
      }),
      _format.splat(),
      _format.prettyPrint()
    ),
  })

  DBConnection(stg) {
    return getConnectionString('ODSConfig', stg)
  }

  constructor(params = {}) {
    this.files = params.Files
    this.envStage = params.Stage || process.env.STAGE || 'dev'
    this.dBConnection = params.DBConnection || this.DBConnection(this.envStage)
    // initialize non params
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel || 'info'
    this.logger.add(this.consoleTransport)
  }

  IsValidParameters() {
    if (!_.isUndefined(this.files) && !_.isArray(this.files)) {
      throw new Error(
        `Invalid Params. params.Files should be not empty and should be an Array. ${params}`
      )
    }
  }

  async createPipeLineQueueEntries() {
    this.IsValidParameters()
    try {
      this.logger.log('debug', `Creating PipeLine Queue Entries.`)
      //if no files to save then skip
      if (_.size(this.files) <= 0) {
        return -1
      }
      const qParams = {
        Query: getSQLScript(idx),
        ConnectionString: this.dBConnection,
        BatchKey: undefined,
      }
      const dbResp = await executeScalar(qParams)
      this.logger.log('debug', `Creating PipeLine Queue Entries DB Resp. ${JSON.stringify(dbResp)}`)
      if (!dbResp.completed || !_.isUndefined(dbResp.error)) {
        throw new Error(
          `Error updating SQL Table: ${table.CleanTableName}, error: ${dbResp.error.message}`
        )
      } else {
        return dbResp.scalarValue
      }
    } catch (err) {
      this.logger.log('error', `Error in Setting Initial Load PipeLine: ${err.message}`)
      throw new Error(`Error in createPipeLineQueueEntries: ${err.message}`)
    }
  }

  getSQLScript(index) {
    return `SELECT * FROM public."udf_Set_DataPipeLineInitialImport"(${JSON.stringify(
      this.files
    )}::jsonb);`
  }
}

export async function queueInitialImport(event = {}) {
  const objQueue = new QueueInitialImport(event)
  const resp = await objQueue.createPipeLineQueueEntries()
  return resp
}
