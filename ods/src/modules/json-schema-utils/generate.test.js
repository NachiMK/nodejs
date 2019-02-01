import { GetSchemaOfSimplePropByDataPath, generateSchemaByData } from './index'
import { GetJSONFromS3Path } from '../s3ODS'

const arryOfTestPaths2 = [
  '',
  'Cart',
  'Cart.NotIncluded',
  'Cart.Benefits',
  'Cart.Benefits.Math',
  'Cart.Benefits.Math.Formulas',
  'Cart.Benefits.Math.Family',
  'Cart.Benefits.Math.Family.MonthlyRates',
  'Cart.Benefits.Persons',
]

const arryOfTestPaths = ['Cart', 'Cart.NotIncluded', 'Cart.Benefits.Math.Family.MonthlyRates']

describe('GetSchemaOfSimplePropByDataPath - Unit Tests', () => {
  it.skip('GetSchemaOfSimplePropByDataPath Unit test', async () => {
    const jSchema = require('./testSchema.json')
    arryOfTestPaths.forEach((val, idx) => {
      try {
        const opts = { ExcludeObjects: true, ExcludeArrays: true }
        const stgResp = GetSchemaOfSimplePropByDataPath(jSchema, val, opts)
        expect(stgResp).toBeDefined()
        expect(stgResp.Schema).toBeDefined()
        expect(stgResp.HadNestedProperties).toBeDefined()
        console.log(`Path: ${val}, Index: ${idx}, Schema: ${JSON.stringify(stgResp, null, 2)}`)
      } catch (err) {
        console.log('error', err.message)
        expect(err).toBeUndefined()
        // continue on error for testing other paths
      }
    })
  })
  it.only('Get Schema By Data Path - Unit test - generateSchema', async () => {
    const jsonData = await GetJSONFromS3Path(
      's3://dev-ods-data/unit-test/cart/cart-Data-_debug_20180913_195513557.json'
    )
    try {
      const opts = { GenerateLengths: false, SimpleArraysToObjects: true }
      const stgResp = generateSchemaByData('', jsonData, opts)
      expect(stgResp).toBeDefined()
      console.log(JSON.stringify(stgResp, null, 2))
    } catch (err) {
      console.error(`error: ${err.message}`)
      expect(err).toBeUndefined()
    }
  })
})
