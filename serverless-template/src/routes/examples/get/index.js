import fortuneCookie from 'fortune-cookie'
import ware from 'warewolf'
import { before, after, queryStringIsTrue } from '../../../utils'

export const get = ware(
  before,

  async (event) => {
    // grab a random fortune from the 'fortune-cookie' module
    const fortune = fortuneCookie[Math.floor(Math.random() * 250) + 1]
    const message = 'success!'
    const nodeVersion = process.versions.node

    event.result = {
      fortune,
      message,
      'node version': nodeVersion,
    }

    // if `showEvent` qs-param is true...
    if (queryStringIsTrue(event.query.showEvent)) {
      event.result.event = { ...event }
    }
  },

  after,
)
