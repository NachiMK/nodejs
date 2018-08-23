import { DataPipeLineTaskQueue } from './index'

async function testDataPipeLineTaskQueueClass() {
  const objPipeLineTask = new DataPipeLineTaskQueue({ DataPipeLineTaskQueueId: 3 })
  await objPipeLineTask.loadAttributes()
  console.log('PipeLineTask:', JSON.stringify(objPipeLineTask, null, 2))
  Object.keys(objPipeLineTask.TaskQueueAttributes).forEach((item) =>
    console.log(`Name: ${item} , Value: ${objPipeLineTask.getTaskAttributeValue([item])}`)
  )
}

testDataPipeLineTaskQueueClass()

// npm run build && odsloglevel=info STAGE=DEV log_dbname=ODSLog node lib/modules/ODSConfig/DataPipeLineTaskQueue/generate-test.js
