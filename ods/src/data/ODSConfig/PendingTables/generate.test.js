import { GetPendingPipeLineTables } from './getPendingTables'

GetPendingPipeLineTables(2)
  .then((res) => console.log('res', res))
  .catch((e) => console.log('error', e))

// npm run build && odsloglevel=info STAGE=DEV log_dbname=ODSLog node lib/data/ODSConfig/PendingTables/generate-test.js
