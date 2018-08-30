import { JsonToPSQL } from '.'
import { getAndSetVarsFromEnvFile } from '../../../../env'

const event = require('./event.json')

console.log(`stage:${process.env.STAGE}, STAGE: ${process.env.STAGE}`)
getAndSetVarsFromEnvFile(false)
JsonToPSQL(event)
  .then((res) => {
    console.log('result:', JSON.stringify(res, null, 2))
  })
  .catch((err) => {
    console.error('error in json to psq:', err.message)
  })
