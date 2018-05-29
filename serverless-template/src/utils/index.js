import { isError, isString } from 'lodash'
import circular from 'circular-json'
import http from 'http'
import stripAnsiColors from 'strip-ansi'
import ware from 'warewolf'

const { STAGE } = process.env
export const isProd = /^prod(?:uction)?$/gim.test(STAGE)
export const getStatus = thing => text => !!thing.match(new RegExp(`^${text}$`, 'i'))
export const isComplete = getStatus('completed')

const defaultResponseConfig = {
  headers: {
    'Access-Control-Allow-Credentials': true, // Required for cookies, authorization headers with HTTPS
    'Access-Control-Allow-Origin': '*',       // Required for CORS support to work
    'Content-Type': 'text/html;charset=utf-8',
    // 'Content-Type': 'application/json',
  },
  isBase64Encoded: false,
  statusCode: 200,
}

function responseController(getResults = ({ result }) => {
  /* eslint-disable no-nested-ternary */
  switch (typeof result) {
    case 'string':
      return { result }
    case 'object':
      return Array.isArray(result) ? [...result] : { ...result }
    case 'undefined':
      // not sure how we should be handling this
      return {}
    default:
      return { ...result }
  }
}) {
  return (event, context, done) => {
    const result = getResults(event)
    const response = {
      ...defaultResponseConfig,
      ...event,
      headers: {
        ...defaultResponseConfig.headers,
        ...event.headers,
      },
      body: Array.isArray(result)
        ? circular.stringify([...result])
        : circular.stringify({ ...result }),
    }
    done(null, response)
  }
}

const errorHandler = (error, event, context, done) => {
  if (isError(error)) {
    const { statusCode, type, message } = getFormattedError(error, event)
    const isInDebugMode = /^\*$/.test(process.env.SLS_DEBUG) // check for '*'
    const isDevOrInt = /^(?:int|dev)$/i.test(process.env.STAGE) // check for 'dev' or 'int'
    const shouldPrintStack = isInDebugMode && isDevOrInt
    // add stack trace if running in 'dev' or 'int, and have opted-in
    const stack = shouldPrintStack ? error.stack : undefined

    done(null, {
      ...defaultResponseConfig,
      headers: {
        ...defaultResponseConfig.headers,
      },
      statusCode,
      body: JSON.stringify({
        status: statusCode,
        type,
        message,
        stack,
      }),
    })
    return
  }
  done()
}

function getFormattedError(error = {}, event = {}) {
  let { statusCode = 500 } = event
  if (error.statusCode) {
    ({ statusCode } = error)
  }
  if (Number.isInteger(error)) {
    statusCode = error
  }
  statusCode = Number.parseInt(statusCode, 10)
  const type = http.STATUS_CODES[statusCode] || 'An Error Has Occurred'
  const message = error.message ? error.message : `${statusCode}: ${type}`

  return { statusCode, type, message }
}

export const before = ware(async (event = {}) => {
  const {
    body = {},
    pathParameters = {},
    query = {},
    queryStringParameters = {},
  } = event

  event.stage = process.env.STAGE
  event.params = { ...queryStringParameters, ...pathParameters, ...query }
  event.body = isString(body) ? JSON.parse(body) : body
})

export const after = ware(
  async (event) => {
    event.body = event.result || event.results || {}
  },

  responseController(),
  errorHandler,
)

export const isTrue = value =>
  value && value != null && [true, 'true', 1, '1', 'yes'].includes(value)

export const stripNonAlphaNumericChars = value => `${value}`.replace(/[^\w\s]*/gi, '')

export const isSetToTrue = queryStringIsTrue
export function queryStringIsTrue(queryString) {
  return isTrue(stripNonAlphaNumericChars(queryString))
}

const logLevel = 'info'

/* eslint-disable no-console */
export function horizontalRule(width = 78, character = '—', shouldConsoleLog = false) {
  if (shouldConsoleLog) {
    return character.repeat(width)
  }
  return console[logLevel](`|${character.repeat(width)}|`)
}
export function newline() { console[logLevel](horizontalRule(1, '', true)) }

export const centerText = centerContent
export function centerContent(content = '', maxWidth = 78, spacing = Math.floor((maxWidth - stripAnsiColors(content).length) / 2)) {
  const repeatAmount = (maxWidth - (`${horizontalRule(spacing, ' ', true)}${stripAnsiColors(content)}${horizontalRule(spacing, ' ', true)}`).length) < 0 ? 0 : (maxWidth - (`${horizontalRule(spacing, ' ', true)}${stripAnsiColors(content)}${horizontalRule(spacing, ' ', true)}`).length)
  console[logLevel](`|${horizontalRule(spacing, ' ', true)}${content}${horizontalRule(spacing, ' ', true)}${' '.repeat(repeatAmount)}|`)
}

let initialLineHasBeenDrawn = false
export const drawInitialNewline = () => {
  if (initialLineHasBeenDrawn) {
    return false
  }

  initialLineHasBeenDrawn = true
  newline()
  horizontalRule()
  return true
}

export function getSubdomainPrefix(apiRootName = 'api', stage) {
  if (stage === 'prod') return `${apiRootName}`
  if (stage === 'int') return `int-${apiRootName}`
  if (stage === 'dev') return `dev-${apiRootName}`

  // if none of the above trigger, then return a default of dev"
  centerText('WARNING: Couldn\'t detect STAGE')
  return `dev-${apiRootName}`
}
