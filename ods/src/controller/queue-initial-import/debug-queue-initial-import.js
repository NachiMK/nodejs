import { queueInitialImport } from './queue-initial-import'
import { getAndSetVarsFromEnvFile } from '../../../env'

const event = require('./clients-event.json')

getAndSetVarsFromEnvFile(false)
queueInitialImport(event)
  .then((res) => {
    console.log(`Results queuing the files: ${JSON.stringify(res, null, 2)}`)
  })
  .catch((err) => {
    console.log(`Error queueing import: ${JSON.stringify(err.message)}`)
  })
