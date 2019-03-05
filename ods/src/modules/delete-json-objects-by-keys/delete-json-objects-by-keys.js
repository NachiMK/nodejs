import _ from 'lodash'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { GetJSONFromS3Path } from '../s3ODS/index'

const logger = createLogger({
  format: _format.combine(
    _format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss',
    }),
    _format.splat(),
    _format.prettyPrint()
  ),
})

/**
 *
 * @param {JsonData, CommaSeparatedPaths, LogLevel} param0
 *
 * This method looks at given data in JsonData and removes
 * object that matches any of given Paths. It doesn't alter the
 * object that was sent in. The new object with deleted keys is returned
 * to the caller. If no key matches then whatever was sent in will be returned.
 *
 * You can pass in more than on Paths, each path is separated by comma
 *
 * Each Path is like this Key1.ChildKey2.GrandChildKey3
 *
 */
export function deleteByPath({ JsonData, CommaSeparatedPaths, LogLevel }) {
  initializeLogger(LogLevel)
  const copyOfData = _.cloneDeep(JsonData)
  if (copyOfData && CommaSeparatedPaths) {
    // split paths
    const pathsToDel = CommaSeparatedPaths.split(',')
    // loop through each given Path
    if (_.size(pathsToDel) > 0) {
      logMsg(`No Of Paths to Delete: ${_.size(pathsToDel)}`, 'debug')
      _.forEach(pathsToDel, (path) => {
        logMsg(`Deleting Path: ${path}`, 'debug')
        // if array loop and delete
        if (_.isArray(copyOfData)) {
          _.forEach(copyOfData, (objToDelete, idx) => {
            logMsg(`Deleting Object at indecx: ${idx}`, 'debug')
            recursiveDeleteByKey({ JsonData: objToDelete, PathToDelete: path })
          })
        }
        // else delete on object
        logMsg(`Deleting Object`, 'debug')
        recursiveDeleteByKey({ JsonData: copyOfData, PathToDelete: path })
      })
    }
  }
  logMsg(`Returning updated object IsDefined: ${copyOfData}`, 'info')
  logMsg(`Updated object`, 'debug', copyOfData)
  return copyOfData
}

/**
 *
 * @param {S3FilePath, CommaSeparatedPaths, LogLevel} param0
 *
 * This method looks at given json data in the S3 file and removes
 * object that matches any of given Paths. It doesn't update
 * the actual file. It only removes the data and sends  it back
 * to the caller. If no key matches then whatever is in the file will be returned.
 *
 * You can pass in more than on Paths, each path is separated by comma
 *
 * Each Path is like this Key1.ChildKey2.GrandChildKey3
 */
export async function deleteInFileByPath({ S3FilePath, CommaSeparatedPaths, LogLevel }) {
  initializeLogger(LogLevel)
  const dataFromFile = await GetJSONFromS3Path(S3FilePath)
  logMsg(`Data in File is available? ${dataFromFile}`, 'info')
  return deleteByPath({ JsonData: dataFromFile, CommaSeparatedPaths, LogLevel })
}

/**
 *
 * @param {SingleJsonObject, PathToDelete, LogLevel} param0
 *
 * This method looks at given data in JsonData and removes
 * object that matches the given Path. It doesn't alter the
 * object that was sent in. The new object with deleted keys is returned
 * to the caller. If no key matches then whatever was sent in will be returned.
 *
 *
 * Path To Delete is like this Key1.ChildKey2.GrandChildKey3
 *
 */
export function deleteBySinglePath({ SingleJsonObject, PathToDelete, LogLevel }) {
  initializeLogger(LogLevel)
  if (SingleJsonObject) {
    logMsg(`Cloning and deleting objects`, LogLevel)
    return recursiveDeleteByKey({ JsonData: _.cloneDeep(SingleJsonObject), PathToDelete })
  }
  return SingleJsonObject
}

function recursiveDeleteByKey({ JsonData, PathToDelete }) {
  logMsg(`Object Exists: ${JsonData}, Path: ${PathToDelete}`, 'debug')
  if (JsonData && PathToDelete && PathToDelete.length > 0) {
    // split the path
    const paths = PathToDelete.split('.')
    const firstKey = paths[0]
    logMsg(`Path Entries: ${_.size(paths)}`, 'debug')
    if (JsonData[firstKey]) {
      if (_.size(paths) > 1) {
        // remaining path
        const remainingPath = paths.slice(1).join('.')
        // is the current item an array?
        if (_.isArray(JsonData[firstKey])) {
          // loop through and delete as required.
          _.forEach(JsonData[`${firstKey}`], (objToDel, idx) => {
            logMsg(`Deleting item at: ${idx}`)
            recursiveDeleteByKey({ JsonData: objToDel, PathToDelete: remainingPath })
          })
        } else {
          // call recursively for regular object that is not an array
          logMsg(`Remaining Path Entries: ${remainingPath}`, 'debug')
          recursiveDeleteByKey({
            JsonData: JsonData[`${firstKey}`],
            PathToDelete: remainingPath,
          })
        }
      } else {
        logMsg(`Deleting entry at : ${firstKey}`, 'debug')
        delete JsonData[`${firstKey}`]
        logMsg(`Does the deleted entry exists? : ${JsonData[firstKey]}`, 'debug')
      }
    }
  }
  return JsonData
}

function logMsg(msg, logLevel = 'warn', objectsToLog = undefined) {
  logger.log(logLevel, msg, objectsToLog, null)
}

function initializeLogger(logLevel) {
  const consoleTransport = new _transports.Console()
  consoleTransport.level = logLevel
  logger.add(consoleTransport)
}
