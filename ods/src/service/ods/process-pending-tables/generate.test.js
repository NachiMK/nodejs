import { getAndSetVarsFromEnvFile } from '../../../../env'
import { processPendingTables } from './process-tables'

console.time('process-pending-table')
getAndSetVarsFromEnvFile(false)
const event = { TableLimit: 1 }
processPendingTables(event)
  .then((res) => {
    console.log('result:', JSON.stringify(res, null, 2))
    console.timeEnd('process-pending-table')
  })
  .catch((err) => {
    console.error('error in json to psq:', err.message)
    console.timeEnd('process-pending-table')
  })
