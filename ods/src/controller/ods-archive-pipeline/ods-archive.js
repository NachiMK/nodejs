import _ from 'lodash'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { getConnectionString, executeScalar, executeQueryRS } from '../../data/psql'

export class ODSArchive {
  logger = createLogger({
    format: _format.combine(
      _format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss',
      }),
      _format.splat(),
      _format.prettyPrint()
    ),
  })

  ConfigDBConn(stg) {
    return getConnectionString('ODSConfig', stg)
  }

  ArchiveDBConn(stg) {
    return getConnectionString('ODSArchive', stg)
  }

  constructor(params = {}) {
    this._tables = params.Tables || ''
    this.envStage = params.Stage || process.env.STAGE || 'dev'
    this._S3ArchiveBucket = params.S3ArchiveBucket || ''
    this._maxTask = !isNaN(parseInt(params.MaxTasksToArchive)) ? params.MaxTasksToArchive : 25
    this._cutOffDays = !isNaN(parseInt(params.CutOffDays)) ? params.CutOffDays : 15
    this._S3LifeCycleOption = params.S3LifeCycleOption || 'Archive'
    this._logLevel = params.LogLevel || 'warn'
    this._ConfigDBConnection = params.ConfigDB || this.ConfigDBConn(this.envStage)
    this._ArchiveDBConnection = params.ArchiveDB || this.ArchiveDBConn(this.envStage)

    // initialize non params
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = this._logLevel
    this.logger.add(this.consoleTransport)
  }

  get Tables() {
    return this._tables
  }
  get S3ArchiveBucket() {
    return this._S3ArchiveBucket
  }
  get MaxTasksToArchive() {
    return this._maxTask
  }
  get CutOffDays() {
    return this._cutOffDays
  }
  get S3LifeCycleOption() {
    return this._S3LifeCycleOption
  }
  get LogLevel() {
    return this._logLevel
  }
  get ConfigDBConnection() {
    return this._ConfigDBConnection
  }
  get ArchiveDBConnection() {
    return this._ArchiveDBConnection
  }

  PrintParams() {
    return `
    Tables: ${this.Tables}
    S3ArchiveBucket: ${this.S3ArchiveBucket}
    MaxTask: ${this.MaxTask}
    CutOffDays: ${this.CutOffDays}
    LogLevel: ${this.LogLevel}
    ConfigDBConnection: ${this.ConfigDBConnection}
    ArchiveDBConnection: ${this.ArchiveDBConnection}
    `
  }
  IsValidParams() {
    if (this.S3LifeCycleOption !== 'Archive' || this.S3LifeCycleOption !== 'Delete') {
      throw new Error(
        `Invalid Param. S3LifeCycleOption should be Archive/Delete and case sensitive.`
      )
    }
    if (this.S3LifeCycleOption === 'Archive' && _.isEmpty(this.S3ArchiveBucket)) {
      throw new Error(`Invalid Param. S3ArchiveBucket is required.`)
    }
    if (_.isEmpty(this.ConfigDBConnection)) {
      throw new Error(`Invalid Param. ConfigDB is required.`)
    }
    if (_.isEmpty(this.ArchiveDBConnection)) {
      throw new Error(`Invalid Param. ArchiveDB is required.`)
    }
  }
  async ArchiveTasksAndFiles() {
    this.IsValidParams()
    try {
      // Get Completed Tasks
      const completed = await this.GetCompletedTasks()
      // Get Tasks/Attributes of Completed Tasks
      const tasks = await this.GetTasksToArchive(completed)
      const attributes = await this.GetAttributesToArchive(completed)
      // Find the list of S3 files from Attributes
      // Queue the S3 files to Archive
      await this.QueueS3FilesToArchive(attributes)
      // Archive Those tasks/Attributes
      const archiveResp = await this.ArchiveTasksAndAttributes(tasks, attributes)
      // Delete the Task/Attributes
      await this.DeleteArchivedTasks(tasks, attributes, archiveResp)
    } catch (err) {
      this.logger.log(`error`, `Error in Archiving: ${err.message}`)
      throw new Error(`Error in Archiving: ${err.message}`)
    }
  }

  async GetCompletedTasks() {
    let completedTasks = []
    try {
      this.logger.log('debug', `Getting Completed Tasks.`)
      const qParams = {
        Query: `SELECT ods."udf_GetCompletedTasks"('${this.Tables}', ${this.CutOffDays}, ${
          this.MaxTasksToArchive
        })  AS "CompletedTasks";`,
        ConnectionString: this.ConfigDBConnection,
        BatchKey: undefined,
        DoNotLog: true,
      }
      const retRS = await executeScalar(qParams)
      this.logger.log(
        `debug`,
        `DB Response for getting tasks: ${retRS.completed}, error: ${retRS.error}`
      )
      if (retRS.completed === true) {
        this.logger.log(`debug`, `Getting Scalar Value of Completed Tasks`)
        completedTasks = JSON.parse(retRS.scalarValue)
      } else {
        throw new Error(`Error in getting completed Tasks: ${JSON.stringify(retRS.error, null, 2)}`)
      }
      this.logger.log('info', `Completed Task Count: ${_.size(completedTasks)}`)
      this.logger.log('debug', `Completed Task details: ${JSON.stringify(completedTasks, null, 2)}`)
      return completedTasks
    } catch (err) {
      this.logger.log('error', `Error in getting completed Tasks: ${err.message}`)
      throw new Error(`Error in getting completed Tasks: ${err.message}`)
    }
  }

  async GetTasksToArchive(completedTasks) {
    let tasksToArchive = []
    try {
      this.logger.log('debug', `Getting Tasks to Archive.`)
      const qParams = {
        Query: `SELECT json_agg(T) AS "TasksToArchive"
                FROM ods."udf_GetPipeLineTask_Archive"('${JSON.stringify(
                  completedTasks
                )}'::jsonb) AS T;`,
        ConnectionString: this.ConfigDBConnection,
        BatchKey: undefined,
        DoNotLog: true,
      }
      const retRS = await executeScalar(qParams)
      this.logger.log(
        `debug`,
        `DB Response for getting tasks: ${retRS.completed}, error: ${retRS.error}`
      )
      if (retRS.completed === true) {
        this.logger.log(`debug`, `Getting Scalar Value of Tasks to Archive`)
        tasksToArchive = retRS.scalarValue
      } else {
        throw new Error(
          `DB Error getting Task details for completed Tasks. ${JSON.stringify(retRS.error)}`
        )
      }
      this.logger.log('info', `Tasks to Archive Count: ${_.size(tasksToArchive)}`)
      this.logger.log('debug', `Archive Task details: ${JSON.stringify(tasksToArchive, null, 2)}`)
      return tasksToArchive
    } catch (err) {
      this.logger.log('error', `Error in getting Tasks to Archive: ${err.message}`)
      throw new Error(`Error in getting Tasks to Archive: ${err.message}`)
    }
  }

  async GetAttributesToArchive(completedTasks) {
    let attributesToArch = []
    try {
      this.logger.log('debug', `Getting Attributes to Archive.`)
      const qParams = {
        Query: `SELECT json_agg(A) AS "AttributesToArchive"
                FROM ods."udf_GetTaskAttributeLog_Archive"('${JSON.stringify(
                  completedTasks
                )}'::jsonb) AS A;`,
        ConnectionString: this.ConfigDBConnection,
        BatchKey: undefined,
        DoNotLog: true,
      }
      const retRS = await executeScalar(qParams)
      this.logger.log(
        `debug`,
        `DB Response for getting attributes: ${retRS.completed}, error: ${retRS.error}`
      )
      if (retRS.completed === true) {
        this.logger.log(`debug`, `Getting Scalar Value of Attributes`)
        attributesToArch = retRS.scalarValue
      } else {
        throw new Error(
          `DB Error getting Attribute details for completed Tasks. ${JSON.stringify(retRS.error)}`
        )
      }
      this.logger.log('info', `Attributes to Archive Count: ${_.size(attributesToArch)}`)
      return attributesToArch
    } catch (err) {
      this.logger.log('error', `Error in getting Attributes to Archive: ${err.message}`)
      throw new Error(`Error in getting Attributes to Archive: ${err.message}`)
    }
  }

  async ArchiveTasksAndAttributes(tasks, attributes) {
    const archivedTasks = await this.saveToArchiveDB('DataPipeLineTaskQueue', tasks)
    const archivedAttributes = await this.saveToArchiveDB('TaskQueueAttributeLog', attributes)
    this.logger.log(
      'debug',
      `Results archived tasks: ${_.size(archivedTasks)}, attributes archive id: ${_.size(
        archivedAttributes
      )}`
    )
    return archivedTasks.concat(archivedAttributes)
  }

  async saveToArchiveDB(recordType, recordsToSave) {
    let ArchiveIDs = []
    try {
      this.logger.log(
        'debug',
        `Archiving ${recordType}. No of records to archive: ${_.size(recordsToSave)}`
      )
      //if no files to save then skip
      if (_.size(recordsToSave) <= 0) {
        return ArchiveIDs
      }
      if (recordType !== 'DataPipeLineTaskQueue' && recordType !== 'TaskQueueAttributeLog') {
        throw new Error(
          `Invalid Param. Record type : ${recordType} to Archive is not Allowed type.`
        )
      }
      const proc =
        recordType === 'DataPipeLineTaskQueue'
          ? 'udf_Archive_DataPipeLineTaskQueue'
          : 'udf_Archive_TaskQueueAttributeLog'
      const qParams = {
        Query: `SELECT arch."${proc}"('${JSON.stringify(recordsToSave)}'::jsonb);`,
        ConnectionString: this.ArchiveDBConnection,
        BatchKey: undefined,
        DoNotLog: true,
      }
      this.logger.log(`debug`, `Running query: ${JSON.stringify(qParams)} to save to DB.`)
      const retRS = await executeQueryRS(qParams)
      if (retRS.rows.length > 0) {
        ArchiveIDs = await Promise.all(
          retRS.rows.map(async (dataRow) => {
            return dataRow.ArchiveId
          })
        )
      } else {
        throw new Error(
          `Error Archiving ${recordType}, DB Call returned 0 rows. ${JSON.stringify(
            retRS.error,
            null,
            2
          )}`
        )
      }
      this.logger.log('info', `Archived ${recordType}, Archive Count: ${_.size(ArchiveIDs)}`)
      return ArchiveIDs
    } catch (err) {
      this.logger.log('error', `Error in Archiving ${recordType}: ${err.message}`)
      throw new Error(`Error in Archiving ${recordType}: ${err.message}`)
    }
  }

  async QueueS3FilesToArchive(attributes) {
    try {
      if (_.size(attributes) > 0) {
        // find which files to archive
        // loop through and archive them
      }
    } catch (err) {
      this.logger.log('error', `Error in Archiving Fiels to S3: ${err.message}`)
      throw new Error(`Error in Archiving Fiels to S3: ${err.message}`)
    }
  }

  async DeleteArchivedTasks(archivedTasks, archivedAttriubutes, archiveIDs) {
    if (_.size(archivedTasks) > 0 && _.size(archivedAttriubutes) > 0 && _.size(archiveIDs) > 0) {
      const totalCount = _.size(archivedTasks) + _.size(archivedAttriubutes)
      if (totalCount !== _.size(archiveIDs)) {
        throw new Error(
          `Deletion of Archive IDs stopped. Archive Count: ${_.size(
            archiveIDs
          )} doesnt match with Total Count :${totalCount}`
        )
      }
      // delete
      let qParams = {
        Query: `SELECT ods."udf_Delete_DataPipeLineTaskQueue"('${JSON.stringify(
          archivedTasks
        )}'::jsonb);`,
        ConnectionString: this.ConfigDBConnection,
        BatchKey: undefined,
        DoNotLog: true,
      }
      let retRS = await executeScalar(qParams)
      this.logger.log(
        `debug`,
        `DB Response for deleting tasks: ${retRS.completed}, error: ${retRS.error}`
      )
      if (retRS.completed !== true) {
        this.logger.log(
          `error`,
          `DB Response for deleting attributes: ${retRS.completed}, error: ${retRS.error}`
        )
      }
      // delete attributes
      qParams = {
        Query: `SELECT ods."udf_Delete_TaskQueueAttributeLog"('${JSON.stringify(
          archivedAttriubutes
        )}'::jsonb);`,
        ConnectionString: this.ConfigDBConnection,
        BatchKey: undefined,
        DoNotLog: true,
      }
      retRS = await executeScalar(qParams)
      this.logger.log(
        `debug`,
        `DB Response for deleting attributes: ${retRS.completed}, error: ${retRS.error}`
      )
      if (retRS.completed !== true) {
        this.logger.log(
          `error`,
          `DB Response for deleting attributes: ${retRS.completed}, error: ${retRS.error}`
        )
      }
    } else {
      this.logger.log('warn', 'Nothing to Delete after archiving.')
    }
  }
}
