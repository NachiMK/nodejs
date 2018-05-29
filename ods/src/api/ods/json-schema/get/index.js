import ware from 'warewolf'
import { before, after } from '@hixme/before-after-middleware'
import jsonSchemaBuilder from '../../../../modules/json-schema-builder'

export const build = ware(
   before,
  async (event) => {
    event.result = await jsonSchemaBuilder(event.queryAndParams)
  },
  after,
)
