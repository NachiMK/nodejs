import { generateSchemaByData } from './index'
import { GetJSONFromS3Path, SaveJsonToS3File } from '../s3ODS'

GetJSONFromS3Path(
  's3://int-ods-data/unit-test/client-benefits/schema-builder/clients-benefits-bare-data.json'
)
  .then((jsonData) => {
    try {
      const opts = { GenerateLengths: false, SimpleArraysToObjects: true }
      const stgResp = generateSchemaByData('', jsonData, opts)
      console.log(JSON.stringify(stgResp, null, 2))
      SaveJsonToS3File(stgResp, {
        S3OutputBucket: 'int-ods-data',
        S3OutputKey: 'unit-test/client-benefits/schema-builder/clients-benefits-bare-raw-schema-',
      })
        .then((saveresult) => {
          console.log(`Saved file: ${saveresult}`)
        })
        .catch((err) => {
          console.log(`Save error:${err.message}`)
        })
    } catch (err) {
      console.error(`error: ${err.message}`)
    }
  })
  .catch((err) => {
    console.log(err.message)
  })
