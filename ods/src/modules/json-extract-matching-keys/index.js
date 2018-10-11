import isUndefined from 'lodash/isUndefined'
import isBoolean from 'lodash/isBoolean'
import { isNumber } from 'util'

export function ExtractMatchingKeyFromSchema(odsSchema, keyName, opts = {}) {
  const retObjSchema = {}
  try {
    let includeLen =
      !isUndefined(opts.includeMaxLength) && isBoolean(opts.includeMaxLength)
        ? opts.includeMaxLength
        : false
    let skipObjectsAndArrays =
      !isUndefined(opts.SkipObjectsAndArrays) && isBoolean(opts.SkipObjectsAndArrays)
        ? opts.SkipObjectsAndArrays
        : false
    if (odsSchema.properties) {
      Object.keys(odsSchema.properties).forEach((objectKey) => {
        const currAttributeObj = odsSchema.properties[objectKey]
        // proceed if type is defined.
        if (!isUndefined(currAttributeObj.type)) {
          // get the type
          const typeOfObj = currAttributeObj.type.toLocaleLowerCase()
          // based on type get default or recurse
          switch (typeOfObj) {
            case 'object':
              if (!skipObjectsAndArrays) {
                retObjSchema[objectKey] = ExtractMatchingKeyFromSchema(
                  currAttributeObj,
                  keyName,
                  includeLen
                )
              }
              break
            case 'array':
              // do we have array of objects or array of props?
              if (!skipObjectsAndArrays) {
                retObjSchema[objectKey] = []
                // TODO: Possible error here, DATA:586
                if (
                  !isUndefined(currAttributeObj.items.type) &&
                  currAttributeObj.items.type.localeCompare('object') === 0
                ) {
                  const objInArray = ExtractMatchingKeyFromSchema(
                    currAttributeObj.items,
                    keyName,
                    includeLen
                  )
                  retObjSchema[objectKey].push(objInArray)
                }
              }
              break
            default:
              retObjSchema[objectKey] = currAttributeObj[keyName]
              if (includeLen === true) {
                delete retObjSchema[objectKey]
                retObjSchema[objectKey] = {}
                retObjSchema[objectKey].type = currAttributeObj[keyName]
                // add length if needed
                if (
                  !isUndefined(currAttributeObj.maxLength) &&
                  isNumber(currAttributeObj.maxLength)
                ) {
                  retObjSchema[objectKey].maxLength = currAttributeObj.maxLength
                }
              }
          }
        }
      })
    } // has property check
  } catch (err) {
    console.error(`Error in ExtractMatchingKeyFromSchema ${err.message}`)
    throw err
  }
  return retObjSchema
}
