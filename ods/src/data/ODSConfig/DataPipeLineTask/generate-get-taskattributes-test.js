import { GetPipeLineTaskQueueAttribute } from './index'

GetPipeLineTaskQueueAttribute(2)
  .then((res) => console.log('res', res))
  .catch((e) => console.log('error', e))

// npm run build && odsloglevel=info STAGE=DEV log_dbname=ODSLog node lib/data/ODSConfig/DataPipeLineTask/generate-get-taskattributes-test.js
