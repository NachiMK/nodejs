import { JsonToJsonFlattner } from './JsonToJsonFlattner'
import event from './event.json'

async function testFlattner() {
  console.log('event:', JSON.stringify(event, null, 2))
  const jsonFlatner = new JsonToJsonFlattner(event)
  await jsonFlatner.getNormalizedDataset()
  console.log(`ModuleStatus: ${jsonFlatner.ModuleStatus}`)
  console.log(`NormalizedDataSet:${jsonFlatner.Output.NormalizedDataSet}`)
  const len = Object.keys(jsonFlatner.Output.JsonKeysAndPath).length
  console.log(`len: ${len}`)
  console.log(JSON.stringify(jsonFlatner.Output.JsonKeysAndPath, null, 2))
}

testFlattner()
  .then((res) => {
    console.log(`resp: ${res}`)
  })
  .catch((err) => {
    console.log(`err: ${err.message}`)
  })
