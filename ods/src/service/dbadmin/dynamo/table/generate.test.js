import moment from 'moment'
import { getTableInfoAllTables } from './index'

const fs = require('fs')
let outputPath = `/Users/Nachi/Documents/myjunk/allTableInfo_${moment().format(
  'YYYYMMDD_HHmmssSSS'
)}.json`
if (process.argv.length > 2) {
  let outputPath = process.argv[2]
}
getTableInfoAllTables('prod')
  .then((res) => {
    console.log(`Reults from Table info: ${res}, written to file: ${outputPath}`)
    fs.writeFile(outputPath, JSON.stringify(res, null, 2))
  })
  .catch((err) => {
    console.error(`Error in getting table info, ${err.message}`)
  })
