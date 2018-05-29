import ware from 'warewolf'
import {
  after,
  before,
  isProd,
  queryStringIsTrue,
} from '../../../utils'

export const ping = ware(
  before,

  async (event) => {
    const {
      // eslint-disable-next-line camelcase
      env: { npm_package_version, STAGE } = {},
      versions: { node } = {},
    } = process

    const versions = { node, npm_package_version }

    event.result = {
      message: 'pong!',
      STAGE,
      versions,
    }

    // if `showEvent` query-string is set, then add the entire event
    const { showENV, showEvent } = event.params
    if (queryStringIsTrue(showEvent)) {
      event.result.event = event
    }

    const eventHeadersHost = event.headers && event.headers.Host
    const HTTPRequestPassingThroughHixmeDomain = eventHeadersHost && eventHeadersHost.includes('hixme.com')
    const serviceIsRuningLocally = !HTTPRequestPassingThroughHixmeDomain || event.isOffline
    // NOTE: `event.isOffline` is a serverless-added boolean and it's quite helpful
    const isSafeToDisplayEnvVariables = !isProd && serviceIsRuningLocally

    // if `showENV` query-string is set, then add all environment variables
    if (isSafeToDisplayEnvVariables && queryStringIsTrue(showENV)) {
      event.result.env = process.env
    }
  },

  after,
)
