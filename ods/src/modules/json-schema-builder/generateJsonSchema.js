import { json } from '@hixme/generate-schema';

export async function generateSchema(name, data) {
  const schema = json(name, data, {
    generateEnums: false,
    maxEnumValues: 0,
    generateLengths: false,
  });
  // Remove the array of items from top and just leave object
  return schema;
}
