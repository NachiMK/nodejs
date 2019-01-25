//@ts-check
import _ from 'lodash'
import { json as hixmeSchemaGenerator } from '@hixme/generate-schema'

function FilterObjects(schemaToFilter) {
  return FilterOutSpecificType(schemaToFilter, 'object')
}

function FilterArrays(schemaToFilter) {
  return FilterOutSpecificType(schemaToFilter, 'array')
}

function FilterOutSpecificType(schemaToFilter, typeToFilter = '') {
  const blnHasItems = !_.isUndefined(schemaToFilter.items)
  const schemaCopy = _.cloneDeep(schemaToFilter)
  const schema = !_.isUndefined(schemaCopy.items)
    ? schemaCopy.items.properties
    : schemaCopy.properties
  _.forIn(schema, (val, key) => {
    if (val['type'] === typeToFilter) {
      if (blnHasItems) {
        delete schemaCopy.items.properties[key]
      } else {
        delete schemaCopy.properties[key]
      }
    }
  })
  return schemaCopy
}

export function GetSchemaByDataPath(jsonSchema, dataPath, opts = {}) {
  let retSchema = {}
  const { ExcludeObjects = false, ExcludeArrays = false } = opts
  if (!_.isUndefined(jsonSchema) && !_.isUndefined(dataPath)) {
    // Get the first part of the path.
    const [firstKey] = dataPath.split('.', 1)
    const pathLen = _.size(dataPath.split('.'))
    // Check if I have items or properties
    // if items, get properties.
    const schema = !_.isUndefined(jsonSchema.items)
      ? _.cloneDeep(jsonSchema.items.properties)
      : _.cloneDeep(jsonSchema.properties)
    // within property  find the key
    if (!_.isUndefined(schema) && !_.isUndefined(schema[firstKey])) {
      const firstKeySchema = schema[firstKey]
      if (pathLen > 1) {
        const strRE = `^${firstKey}{1}\\.?`
        const regExPath = new RegExp(strRE, 'gi')
        const remainingPath = dataPath.replace(regExPath, '')
        retSchema = GetSchemaByDataPath(firstKeySchema, remainingPath, opts)
      } else {
        // if simple array then add artifical columns for Array elements
        retSchema = firstKeySchema
      }
    } else if (firstKey.length === 0) {
      retSchema = !_.isUndefined(jsonSchema.items)
        ? _.cloneDeep(jsonSchema.items)
        : _.cloneDeep(jsonSchema)
    } else {
      throw new Error(
        `Error location key: ${firstKey} of path : ${dataPath}, in schema : ${jsonSchema}`
      )
    }
  } else {
    throw new Error('Invalid Param, jsonSchema or dataPath is empty.')
  }
  if (ExcludeObjects) {
    retSchema = FilterObjects(retSchema)
  }
  if (ExcludeArrays) {
    retSchema = FilterArrays(retSchema)
  }
  return retSchema
}

export function generateSchemaByData(name, data, opts = {}) {
  let schema = {}
  const { GenerateLengths = false, SimpleArraysToObjects = false } = opts
  try {
    console.log('About to generate schema for:', name)
    schema = hixmeSchemaGenerator(name, data, {
      generateEnums: false,
      maxEnumValues: 0,
      generateLengths: GenerateLengths,
    })
    if (SimpleArraysToObjects) {
      // Find all simple arrays and convert
      ConvertSimpleArraysToObjects(schema.items)
    }
  } catch (err) {
    schema = {}
    console.error('Error calling hixme generator', JSON.stringify(err, null, 2))
    throw new Error(`Error calling hixme generator or converting Simple Arrays: ${err.mesage}`)
  }

  // Remove the array of items from top and just leave object
  return { name, schema: { $schema: schema.$schema, ...schema.items } }
}

/**
 * Loop through all keys
 * If type => Object => Recurse
 *  If type => Array
 *    IF Array type == simple && then add artifical keys
 *      else if Array type != simple then => Recurse
 *  else skip
 */
function ConvertSimpleArraysToObjects(jsonSchema) {
  try {
    if (jsonSchema.properties) {
      Object.keys(jsonSchema.properties).forEach((objectKey) => {
        const currAttributeObj = jsonSchema.properties[objectKey]
        // proceed if type is defined.
        if (!_.isUndefined(currAttributeObj.type)) {
          // get the type
          const typeOfObj = getSchemaType(currAttributeObj.type).toLocaleLowerCase()
          // based on type get default or recurse
          switch (typeOfObj) {
            case 'object':
              ConvertSimpleArraysToObjects(currAttributeObj)
              // some times objects have both arrays and properties :)
              if (
                !_.isUndefined(currAttributeObj.items) &&
                currAttributeObj.items.type === 'object'
              ) {
                ConvertSimpleArraysToObjects(currAttributeObj.items)
              }
              break
            case 'array':
              if (
                !_.isUndefined(currAttributeObj.items.type) &&
                currAttributeObj.items.type !== 'object'
              ) {
                currAttributeObj.items = {
                  properties: {
                    ArrayIndex: {
                      type: 'integer',
                    },
                    ArrayValue: {
                      type: currAttributeObj.items['type'],
                    },
                  },
                  required: ['ArrayIndex', 'ArrayValue'],
                  type: 'object',
                }
              } else {
                ConvertSimpleArraysToObjects(currAttributeObj.items)
              }
              break
            default:
              break
          }
        }
      })
    } // has property check
  } catch (err) {
    console.error(`Error in ConvertSimpleArraysToObjects ${err.message}`)
    throw new Error(`Error in ConvertSimpleArraysToObjects ${err.message}`)
  }
}

const getSchemaType = (type) => {
  if (Array.isArray(type)) {
    if (type.includes('object')) {
      return 'object'
    } else if (type.includes('string')) {
      return 'string'
    } else if (type.includes('number')) {
      return 'number'
    }

    return type.reduce((memo, key) => key, 'string')
  }

  return type || 'string'
}
