export function ExtractMatchingKeyFromSchema(odsSchema, parentKey, keyName) {
  const retObjSchema = {};
  console.log(`Parameters defined: Obj: ${(odsSchema)}, Parent: ${(parentKey)}`);
  if (odsSchema.properties) {
    Object.keys(odsSchema.properties).forEach((objectKey) => {
      const currAttributeObj = odsSchema.properties[objectKey];
      // proceed if type is defined.
      if ((currAttributeObj.type) && (currAttributeObj.type !== 'undefined')) {
        // get the type
        const typeOfObj = currAttributeObj.type.toLocaleLowerCase();
        // based on type get default or recurse
        switch (typeOfObj) {
          case 'object':
            retObjSchema[objectKey] = ExtractMatchingKeyFromSchema(currAttributeObj, objectKey, keyName);
            break;
          case 'array':
            // do we have array of objects or array of props?
            retObjSchema[objectKey] = [];
            if (currAttributeObj.items.type.localeCompare('object') === 0) {
              const objInArray = ExtractMatchingKeyFromSchema(currAttributeObj.items, undefined, keyName);
              retObjSchema[objectKey].push(objInArray);
            }
            break;
          default:
            retObjSchema[objectKey] = currAttributeObj[keyName];
        }
      }
    });
  }// has property check
  return retObjSchema;
}
