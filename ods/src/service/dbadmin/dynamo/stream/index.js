import { getTablesFromDB } from '../table/index'

const AWS = require('aws-sdk')

const _ = require('lodash')

const AWSDynamoDB = new AWS.DynamoDB({ region: 'us-west-2' })

export const getTablesWithNoStreams = async (TableNameSubString = 'dev') => {
  const tables = await getStreamSpecAllTables()
  if (tables) {
    const tbls = tables.map((tablespec) => {
      const tablename = tablespec.TableName
      if (!tablespec.StreamEnabled && tablename.includes(TableNameSubString)) {
        // stream IS NOT enabled so return it.
        return tablespec.TableName
      }
      return undefined
    })
    return tbls.filter((table) => !_.isUndefined(table))
  }
  return undefined
}

const getStreamSpecAllTables = async (stageName) => {
  const params = {
    ExclusiveStartTableName: stageName,
    Limit: 100,
  }
  const tables = await getTablesFromDB(params)
  const tableStreamSpecs = await Promise.all(
    tables.map(async (tablename) => {
      //
      const streamingTable = await getStreamSpecification(tablename)
      return streamingTable
    })
  )
  console.log(`Tables:${JSON.stringify(tableStreamSpecs, null, 2)}`)
  return tableStreamSpecs
}

const getStreamSpecification = async (tablename) => {
  // let aws_dynamo = new AWS.DynamoDB();
  const params = {
    TableName: tablename,
  }

  const streamdetail = {
    TableName: tablename,
    StreamEnabled: false,
    StreamViewType: '',
  }
  try {
    const descTableData = await AWSDynamoDB.describeTable(params).promise()
    if (descTableData) {
      if (descTableData.Table.StreamSpecification) {
        streamdetail.StreamEnabled = descTableData.Table.StreamSpecification.StreamEnabled
        streamdetail.StreamViewType = descTableData.Table.StreamSpecification.StreamViewType
      } else {
        console.log(`Table :${tablename} has no streams enabled`)
        streamdetail.StreamEnabled = false
      }
      console.log(`Table: ${tablename}, stream details:${streamdetail}`)
    }
  } catch (err) {
    console.warn(`Error in finding Stream status for table ${tablename}, Error: ${err}`)
    console.warn(`Error:${JSON.stringify(err, null, 2)}`)
    streamdetail.StreamEnabled = undefined
  }
  return streamdetail
}

export const EnableStreaming = async (tablename, streamtype = 'NEW_AND_OLD_IMAGES') => {
  const params = {
    StreamSpecification: {
      StreamEnabled: true,
      StreamViewType: streamtype || 'NEW_AND_OLD_IMAGES',
    },
    TableName: tablename,
  }
  try {
    const streanstatus = await getStreamSpecification(tablename)
    console.log(`Table: ${tablename}, Stream Status: ${JSON.stringify(streanstatus, null, 2)}`)
    if (streanstatus && streanstatus.StreamEnabled && streanstatus.StreamEnabled === true) {
      console.log('Stream Already Enabled for Table!')
      return streanstatus.StreamEnabled
    }
    const updateTableResults = await AWSDynamoDB.updateTable(params).promise()
    console.log(`Update Response:${JSON.stringify(updateTableResults, null, 2)}`)
    if (updateTableResults) {
      // check if streaming was enabled
      if (
        updateTableResults.TableDescription &&
        updateTableResults.TableDescription.StreamSpecification
      ) {
        return updateTableResults.TableDescription.StreamSpecification.StreamEnabled
      }
    }
  } catch (err) {
    console.warn(err)
  }
  return false
}

export const DisableStreaming = async (tablename) => {
  const params = {
    StreamSpecification: {
      StreamEnabled: false,
    },
    TableName: tablename,
  }
  const updateTableResults = await AWSDynamoDB.updateTable(params).promise()
  console.log(`Delete Stream Response:${JSON.stringify(updateTableResults, null, 2)}`)
  if (updateTableResults) {
    // check if streaming was enabled
    if (updateTableResults.TableDescription) {
      if (!updateTableResults.TableDescription.StreamSpecification) {
        return true
      }

      const streamspec = updateTableResults.TableDescription.StreamSpecification
      if (!streamspec.StreamEnabled) {
        return streamspec.StreamEnabled
      }
    }
  }
  return false
}

export const EnableStreamingOnTables = async (TableList, streamtype = 'NEW_AND_OLD_IMAGES') => {
  if (TableList) {
    const objRetArray = await Promise.all(
      TableList.map(async (tablename) => {
        const streamEnabledStatus = await EnableStreaming(tablename, streamtype)
        const objRet = {
          TableName: tablename,
          StreamEnabled: streamEnabledStatus,
        }
        return objRet
      })
    )
    return objRetArray
  }
  return undefined
}

export default getStreamSpecAllTables
