import { ExtractMatchingKeyFromSchema } from './index'
import isObject from 'util'

describe('Json extract matching keys - Unit Tests', () => {
  it.only('Json extract matching keys - Default', async () => {
    const event = require('./event.json')
    const resp = await ExtractMatchingKeyFromSchema(event, 'type')
    console.log('resp', JSON.stringify(resp, null, 2))
    expect(resp).toBeDefined()
    expect(resp.SalesDirectorPublicKey).toBeDefined()
    expect(resp.SalesDirectorPublicKey).toEqual('string')
    expect(resp.HixmeConnectCompositePrices).toBeDefined()
    // expect(isObject(resp.SalesDirectorPublicKey)).toBeFalsy()
  })
  it.skip('Json extract matching keys - Test Length', async () => {
    const event = require('./event.json')
    const resp = await ExtractMatchingKeyFromSchema(event, 'type', {
      includeMaxLength: true,
    })
    console.log('resp', JSON.stringify(resp, null, 2))
    expect(resp).toBeDefined()
    expect(resp.SalesDirectorPublicKey).toBeDefined()
    expect(Object.keys(resp.SalesDirectorPublicKey).length).toEqual(2)
    expect(resp.SalesDirectorPublicKey.type).toEqual('string')
    expect(resp.SalesDirectorPublicKey.maxLength).toEqual(36)
  })
  it.skip('Json extract matching keys - Test Skipping Object/Array', async () => {
    const event = require('./event.json')
    const resp = await ExtractMatchingKeyFromSchema(event, 'type', {
      includeMaxLength: true,
      SkipObjectsAndArrays: true,
    })
    console.log('resp', JSON.stringify(resp, null, 2))
    expect(resp).toBeDefined()
    expect(resp.SalesDirectorPublicKey).toBeDefined()
    expect(Object.keys(resp.SalesDirectorPublicKey).length).toEqual(2)
    expect(resp.HixmeConnectCompositePrices).toBeUndefined()
  })
})
