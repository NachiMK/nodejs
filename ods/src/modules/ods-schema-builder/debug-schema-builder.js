import jsonSchemaSaver from '.'
const simple = {
  DataFile:
    's3://int-ods-data/unit-test/client-benefits/schema-builder/clients-benefits-simple-data.json',
  RawSchema:
    's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-simple-raw-schema.json',
  Output:
    's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-simple-combined-',
}
const Full = {
  DataFile:
    's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-full-data.json',
  RawSchema:
    's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-full-raw-schema.json',
  Output:
    's3://int-ods-data/unit-test/client-benefits/schema-builder/client-benefits-full-combined-',
}
const resp = jsonSchemaSaver({
  Datafile: simple.DataFile,
  Output: simple.Output,
  Overwrite: 'yes',
  S3RAWJsonSchemaFile: simple.RawSchema,
})
  .then((res) => {
    console.log(`res: ${JSON.stringify(res, null, 2)}`)
  })
  .catch((err) => {
    console.error(`err: ${JSON.stringify(err)}`)
  })
