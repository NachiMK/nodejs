import { getAndSetVarsFromEnvFile } from '../../../env'
import { pingodsdb } from './pingdb'

function testPings() {
  getAndSetVarsFromEnvFile(false)
  console.log(`testing...`)
  pingodsdb()
    .then((res) => {
      console.log('pingodsdb returned:')
      console.log(`res: ${JSON.stringify(res, null, 2)}`)
    })
    .catch((err) => {
      console.error(`Error in calling pingodsdb: ${err.message}`)
    })
}

testPings()
