import moment from 'moment'
import { getTableInfoAllTables } from './index'

let stgToCapture = 'dev'
if (process.argv.length > 2) {
  stgToCapture = process.argv[2]
}
const fs = require('fs')
let outputPath = `/Users/Nachi/Documents/myjunk/allTableInfo_${stgToCapture}-${moment().format(
  'YYYYMMDD_HHmmssSSS'
)}.json`
if (process.argv.length > 3) {
  outputPath = process.argv[3]
}
console.log(`Capturing Table info for Stage: ${stgToCapture}, Output Path: ${outputPath}`)
getTableInfoAllTables(stgToCapture)
  .then((res) => {
    console.log(`Reults from Table info: ${res}`)
    fs.writeFile(outputPath, JSON.stringify(res, null, 2))
  })
  .catch((err) => {
    console.error(`Error in getting table info, ${err.message}`)
  })
