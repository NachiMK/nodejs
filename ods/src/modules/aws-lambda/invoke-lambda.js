import _ from 'lodash'
import serviceRequest from '@hixme/service-request'

export const invokeLambda = async (params = {}, lambdaPayLoad = {}) => {
  console.log(
    `Invoke Lambda Params: ${JSON.stringify(params, null, 2)}, Payload is Defined? ${!_.isUndefined(
      lambdaPayLoad
    )}`
  )
  if (_.isUndefined(params.FunctionName) || _.isEmpty(params.FunctionName)) {
    console.error(`Invalid Parameter Sent to invoke Lambda. FunctionName is required.`)
    throw new Error(`Invalid Parameter Sent to invoke Lambda. FunctionName is required.`)
  }
  const lambdaFunction = params.FunctionName
  try {
    // find the lambda to invoke
    const svcParams = {
      InvocationType: 'Event',
      region: params.region || 'us-west-2',
    }
    console.log(
      `Calling Lambda: ${lambdaFunction} with Payload:${JSON.stringify(lambdaPayLoad, null, 2)}`
    )
    console.log(`Param to Invoke Lambda: ${JSON.stringify(svcParams, null, 2)}`)
    // invoke lambda
    const resp = await serviceRequest(lambdaFunction, svcParams).request(lambdaPayLoad)
    console.log(`Invoke Lambda Response: ${JSON.stringify(resp)}`)
  } catch (err) {
    console.error(`Error in calling Lambda: ${lambdaFunction}, error: ${err.message}`)
    throw new Error(`Error in calling Lambda: ${lambdaFunction}, error: ${err.message}`)
  }
}
