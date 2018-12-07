import _ from 'lodash'

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
  try {
    const lambdaFunction = params.FunctionName
    const lambda = new aws.Lambda({ region: params.Region || 'us-west-2' })
    // find the lambda to invoke
    const lambdaParams = {
      FunctionName: lambdaFunction,
      InvocationType: 'Event',
      Payload: JSON.stringify(lambdaPayLoad, null, 2),
    }
    console.log(
      `Calling Lambda: ${lambdaFunction} with Payload:${JSON.stringify(lambdaPayLoad, null, 2)}`
    )
    console.log(`Param to Invoke Lambda: ${JSON.stringify(lambdaParams, null, 2)}`)
    // invoke submit lambda
    await lambda.invoke(lambdaParams).promise()
    console.log(`Completed invoking Lambda: ${lambdaFunction}`)
  } catch (err) {
    console.error(`Error in calling Lambda: ${lambdaFunction}, error: ${err.message}`)
    throw new ServerError(`Error in calling Lambda: ${lambdaFunction}, error: ${err.message}`)
  }
}
