import { json } from '@hixme/generate-schema'

export async function generateSchema(name, data) {
  const resp = await json(name, data, {
    generateEnums: false,
    maxEnumValues: 0,
    generateLengths: false,
  })
  // console.log('info', `Schema:${JSON.stringify(resp, null, 2)}`)
  return { name, schema: { $schema: resp.$schema, ...resp.items } }
}
