import jsonSchemaSaver from '.'
const FileOptions = {
  Simple: {
    DataFile:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/clients-benefits-simple-data.json',
    RawSchema:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-simple-raw-schema.json',
    Output:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-simple-combined-',
  },
  Full: {
    DataFile:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-full-data.json',
    RawSchema:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-full-raw-schema.json',
    Output:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-full-combined-',
  },
  Bare: {
    DataFile:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-bare-data.json',
    RawSchema:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-bare-raw-schema.json',
    Output:
      's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-bare-combined-',
  },
}

process.argv.forEach((val, index) => {
  console.log(`Node Command Line Parameters: ${index}: ${val}`)
})

let schemParams
if (process.argv && process.argv.length > 2 && process.argv[2] && process.argv[2].length > 0) {
  console.log(`File Type to process as per command line Args: ${process.argv[2]}`)
  schemParams = FileOptions[process.argv[2]]
}
if (schemParams) {
  schemParams = FileOptions.Bare
  console.error(`Invalid Option was sent, set to Simple/Full/Bare, for now running with Bare files`)
}
console.log(`S3 Files to be used: ${JSON.stringify(schemParams, null, 2)}`)
console.time('jsonSchemaSaver')
const resp = jsonSchemaSaver({
  Datafile: schemParams.DataFile,
  Output: schemParams.Output,
  Overwrite: 'yes',
  S3RAWJsonSchemaFile: schemParams.RawSchema,
})
  .then((res) => {
    console.log(`res: ${JSON.stringify(res, null, 2)}`)
    console.timeEnd('jsonSchemaSaver')
  })
  .catch((err) => {
    console.error(`err: ${JSON.stringify(err)}`)
    console.timeEnd('jsonSchemaSaver')
  })
