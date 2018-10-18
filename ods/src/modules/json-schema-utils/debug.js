import { GetSchemaByDataPath } from './index'

const arryOfTestPaths = [
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

// const arryOfTestPaths = ['Cart.Benefits.Math.Formulas']

const jSchema = require('./testSchema.json')
arryOfTestPaths.forEach((val, idx) => {
  try {
    const opts = { ExcludeObjects: true, ExcludeArrays: true }
    const stgResp = GetSchemaByDataPath(jSchema, val, opts)
    console.log(`Path: ${val}, Index: ${idx}, Schema: ${JSON.stringify(stgResp, null, 2)}`)
  } catch (err) {
    console.log('error', err.message)
    // continue on error for testing other paths
  }
})
