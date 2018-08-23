import { json } from '@hixme/generate-schema'

export async function generateSchema(name, data) {
  return json(name, data, {
    generateEnums: false,
    maxEnumValues: 0,
    generateLengths: false,
  })
}
