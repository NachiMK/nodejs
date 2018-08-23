import { getTableInfo, isTableStatusActive } from '../dynamo/table/index'

const AWS = require('aws-sdk')

const lambda = new AWS.Lambda({ region: 'us-west-2' })

export const LinkTableToTrigger = async (tablename, envStage = '', functionToLink = '') => {
  let streamARN = ''
  const stagename = envStage || process.env.STAGE
  const functionName = `ods-service-${stagename}-dynamodb-to-s3` || functionToLink
  const tblInfo = await getTableInfo(tablename)

  if (tblInfo) {
    streamARN = tblInfo.LatestStreamArn
  }

  const params = {
    EventSourceArn: streamARN,
    FunctionName: functionName,
    StartingPosition: 'LATEST',
    BatchSize: 1000,
  }
  console.log(`Check Status and Create Trigger:${JSON.stringify(params, null, 2)}`)
  try {
    const waitTblresp = await isTableStatusActive(tablename)
    console.log(`Checked Status:${JSON.stringify(waitTblresp, null, 2)}`)
    if (waitTblresp && waitTblresp === true) {
      console.log('Calling CreateEvent Source.')
      const eventResults = await lambda.createEventSourceMapping(params).promise()
      console.log(`Event Source Mapping Response:${JSON.stringify(eventResults, null, 2)}`)
      if (eventResults) {
        // check if streaming was enabled
        if (eventResults.State) {
          return true
        }
      }
    }
  } catch (err) {
    console.warn(
      `Error Linking Table: ${tablename} to Stream/lambda: ${JSON.stringify(params, null, 2)}`
    )
    console.warn(`Error: ${err}`)
  }

  return false
}
