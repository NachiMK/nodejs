import { FakeDataUploader } from './index'

const event = require('./event.json')
const objUploader = new FakeDataUploader(event)
objUploader
  .BatchUpload()
  .then((resp) => {
    console.log(JSON.stringify(resp, null, 2))
  })
  .catch((err) => console.log('error', err.message))
