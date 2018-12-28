import _ from 'lodash'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { getConnectionString, executeQueryRS } from '../../data/psql'

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
    this.files = params[Object.keys(params)[0]].Files
    this.envStage = params.Stage || process.env.STAGE || 'dev'
    this.dBConnection = params.DBConnection || this.DBConnection(this.envStage)
    // initialize non params
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel || 'info'
    this.logger.add(this.consoleTransport)
  }

  IsValidParameters() {
    if (_.isUndefined(this.files) || !_.isArray(this.files)) {
      throw new Error(`Invalid Params. params.Files should be not empty and should be an Array.`)
    }
  }

  async createPipeLineQueueEntries() {
    let importQueueEntries
    this.IsValidParameters()
    try {
      this.logger.log('debug', `Creating PipeLine Queue Entries.`)
      //if no files to save then skip
      if (_.size(this.files) <= 0) {
        return -1
      }
      const qParams = {
        Query: this.getSQLScript(),
        ConnectionString: this.dBConnection,
        BatchKey: undefined,
      }
      const retRS = await executeQueryRS(qParams)
      if (retRS.rows.length > 0) {
        importQueueEntries = await Promise.all(
          retRS.rows.map(async (dataRow) => {
            const retVal = {
              DataPipeLineInitialImportId: dataRow.DataPipeLineInitialImportId,
              SourceEntity: dataRow.SourceEntity,
              S3File: dataRow.S3File,
              ImportSequence: dataRow.ImportSequence,
              DataPipeLineTaskQueueId: dataRow.DataPipeLineTaskQueueId,
              QueuedDtTm: dataRow.QueuedDtTm,
            }
            return retVal
          })
        )
      } else {
        throw new Error('Error Queueing Initial Loads, DB Call returned 0 rows.')
      }
      this.logger.log('info', 'create Import Queue Entries status: %j', importQueueEntries)
      return importQueueEntries
    } catch (err) {
      this.logger.log('error', `Error in Setting Initial Load PipeLine: ${err.message}`)
      throw new Error(`Error in createPipeLineQueueEntries: ${err.message}`)
    }
  }

  getSQLScript() {
    return `SELECT * 
    FROM ods."udf_Set_DataPipeLineInitialImport"('${JSON.stringify(this.files)}'::jsonb);`
  }
}

export async function queueInitialImport(event = {}) {
  const objQueue = new QueueInitialImport(event)
  const resp = await objQueue.createPipeLineQueueEntries()
  return resp
}
