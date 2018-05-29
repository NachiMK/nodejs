import Ajv from 'ajv'
import fs from 'fs'
import { isFunction, isString } from 'lodash'
import fetch from 'node-fetch'

export const validateAjv = getPayload => getJsonSchema => async (event) => {
  const ajv = new Ajv({
    coerceTypes: true,
    allErrors: true,
    verbose: true,
    format: 'full',
    removeAdditional: true,
  })

  let schema = null
  let data = null

  if (isFunction(getJsonSchema)) {
    schema = await getJsonSchema(event)
  } else {
    schema = getJsonSchema
  }

  if (isString(schema)) {
    const exists = fs.existsSync(schema)
    if (exists) {
      schema = JSON.parse(fs.readFileSync(schema, 'utf8'))
    } else {
      const res = await fetch(getJsonSchema)
      schema = await res.json()
    }
  }

  // TODO: Modify schema to allow removing additional (need to do recursively)
  // schema.additionalProperties = false;

  const validate = ajv.compile(schema)

  if (isFunction(getPayload)) {
    data = await getPayload(event)
  } else {
    data = getPayload
  }

  const valid = validate(data)

  if (!valid) {
    const validationErrors = validate.errors.map(item => ({
      message: `${item.dataPath} ${item.message}${Array.isArray(item.schema) ? item.schema : ''}`,
    }))
    const err = new Error('Request is not valid')
    err.errors = validationErrors
    err.statusCode = 400
    throw err
  }
}

export const validateBody = validateAjv(event => event.body)
export const validateQuery = validateAjv(event => event.query)
export const validateParams = validateAjv(event => event.params)
export const validateQueryAndParams = validateAjv(({
  query = {},
  params = {},
}) => Object.assign({}, query, params))
export const validateAll = validateAjv(({
  body = {},
  query = {},
  params = {},
}) => Object.assign({}, body, query, params))
