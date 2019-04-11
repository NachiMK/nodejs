const _ = require("lodash");
const moment = require("moment");
const generator = require("generate-schema");
const Core = require("json-schema-library").cores.Draft04;
const isUUID = require("is-uuid");

/**
 * @function json
 * @description This function returns the Json schema for given data
 *
 * @param {@title} : This is the name of the dynamo table or object you trying to find schema
 * @param {@object}: This is the data that you want to scan and come up with schema
 * @param {@options}: There are multiple options available:
 *  generateEnums :Set this to True if you want to include possible list of enums.
 *                 You can also set maxEnumValues to valid integer on how many enums you want to be returned.
 *  addFormatCounts: Set to true, if you want to know the number of keys that match each of the formats
 *  pickPopularFormat: Set to true, for picking the format based on populate percentage.
 */
module.exports.json = function json(title, object, options = {}) {
  options = Object.assign(
    {},
    { maxEnumValues: 20, generateEnums: false, generateLengths: false },
    options
  );

  var schema = generator.json(title, object);
  addSchemaLimits(schema, object, options);
  return schema;
};

function addSchemaLimits(rootSchema, data, options) {
  const core = new Core(rootSchema);
  const stats = {};
  // Queue up the schema updates
  core.each(rootSchema, data, (schema, value, pointer) => {
    const schemaPointer = pointer.replace(/(\d+)/gi, "*").replace(" / ", " - ");
    // Detect GUIDs and set min/max length to match data
    // Also detect formats: date-time, date
    if (typeof value !== "object" && typeof value !== "array") {
      const stat = stats[schemaPointer] || { schemaUpdateFunctions: [] };
      stat.formats = stat.formats || {};
      if (value.length === 36 && isUUID.anyNonNil(value)) {
        stat.schemaUpdateFunctions.push(s => {
          s.minLength = 36;
          s.maxLength = 36;
        });
        stat.formats["uuid"] = (stat.formats["uuid"] || 0) + 1;
      } else if (moment(value, "YYYY-MM-DD", true).isValid()) {
        stat.formats["date"] = (stat.formats["date"] || 0) + 1;
        stat.schemaUpdateFunctions.push(s => (s.format = "date"));
      } else if (moment(value, moment.ISO_8601, true).isValid()) {
        stat.formats["date-time"] = (stat.formats["date-time"] || 0) + 1;
        stat.schemaUpdateFunctions.push(s => (s.format = "date-time"));
      }
      // booleans are often considered as valid numbers
      // so we need to flag those formats as boolean
      else if (!isNaN(value) && typeof value === "boolean") {
        stat.formats["boolean"] = (stat.formats["boolean"] || 0) + 1;
        stat.schemaUpdateFunctions.push(s => (s.format = "boolean"));
      } else if (!isNaN(value)) {
        stat.formats["number"] = (stat.formats["number"] || 0) + 1;
        stat.schemaUpdateFunctions.push(s => (s.format = "number"));
      } else {
        stat.formats["string"] = (stat.formats["string"] || 0) + 1;
        stat.schemaUpdateFunctions.push(s => (s.format = "string"));
      }

      if (schema.type === "string") {
        // TODO: Detect enumeration values.  This is harder to do efficiently inside the each.
        // If total number of records > 100 but distinct values < 20 assume its an enum.
        // Count the number of times the value has been used
        stat.values = stat.values || {};
        stat.values[value] = (stat.values[value] || 0) + 1;

        // Keep stats on minLength and maxLength
        if (value.length < (stat.minLength || 10000000)) {
          stat.minLength = value.length;
        }
        if (value.length > (stat.maxLength || 0)) {
          stat.maxLength = value.length;
        }
      }
      stats[schemaPointer] = stat;
    }
  });

  // Make the schema updates
  Object.keys(stats).forEach(pointer => {
    const stat = stats[pointer];
    if (options.generateEnums && stat.values) {
      stat.schemaUpdateFunctions.push(
        s => (s.enum = Object.keys(stat.values).slice(0, options.maxEnumValues))
      );
    }
    // // Add formats to schema if options were set for it.
    if (options.addFormatCounts && stat.formats) {
      stat.schemaUpdateFunctions.push(s => (s.formats = stat.formats));
    }
    // Cleanup format if multiple format exists and is requested in options
    if (options.pickPopularFormat && _.size(stat.formats) > 1) {
      findUpdatePopularformat(stat);
    }
    if (options.generateLengths && typeof stat.minLength !== "undefined") {
      stat.schemaUpdateFunctions.push(s => {
        s.minLength = stat.minLength;
        s.maxLength = stat.maxLength;
      });
    }

    updateSchema(rootSchema, pointer, stat.schemaUpdateFunctions);
  });
}

function findUpdatePopularformat(stat) {
  const popularFormats = [];
  let popularFormat;
  // pick the most occured one
  let prevCnt = -1;
  _.forEach(stat.formats, (Cnt, format) => {
    if (Cnt >= prevCnt && Cnt >= 0) {
      if (Cnt > prevCnt) {
        popularFormats.splice(0);
      }
      popularFormats.push({
        FormatName: format,
        Count: Cnt
      });
      prevCnt = Cnt;
    }
  });
  // NOT SURE IF WE SHOULD DO THIS YET.
  // // if we have even one entry (format) as a string then
  // // that super seeds all other formats
  // // eg: if one value is string and all other values are boolean
  // // we should flag the format as string. because that one entry cannot be convereted to boolean :(
  // if (stat.formats["string"]) {
  //   popularFormats.splice(0);
  //   popularFormats.push({
  //     FormatName: "string",
  //     Count: stat.formats["string"]
  //   });
  // }
  // NOT SURE IF WE SHOULD DO THIS YET.

  //if we have at least one popular format
  // then let us find which one to use.
  if (_.size(popularFormats) > 0) {
    // they could be multiple formats that
    // have same count as the popular one
    // in that we have to pick the format
    // that can hold all other formats.
    if (_.size(popularFormats) > 1) {
      // find which one to keep
      _.forEach(popularFormats, format => {
        if (format.FormatName === "string") {
          popularFormat = format.FormatName;
        } else if (
          popularFormat === "date" &&
          format.FormatName === "date-time"
        ) {
          popularFormat = format.FormatName;
        } else if (
          popularFormat !== "string" &&
          format.FormatName !== "string"
        ) {
          popularFormat = "string";
        }
      });
    } else {
      // only one format so just pick it.
      popularFormat = popularFormats[0].FormatName;
    }
  }
  // set the new popular format
  // stat.format = popularFormat || stat.format;
  stat.schemaUpdateFunctions.push(
    s => (s.format = popularFormat || stat.format)
  );
}

function updateSchema(rootSchema, pointer, updateFunctions) {
  if (updateFunctions.length === 0) {
    return;
  }
  const schemaToUpdate = findSchema(rootSchema, pointer);
  if (schemaToUpdate) {
    updateFunctions.forEach(fn => {
      fn(schemaToUpdate);
    });
  }
}

function findSchema(rootSchema, pointer) {
  // Try to find the schema that needs to be updated
  var steps = pointer.split("/");
  var schemaToUpdate = rootSchema;

  steps.forEach(step => {
    if (!schemaToUpdate) {
      console.log("Could not get schema for pointer", pointer);
      return;
    }
    if (step === "#") {
      return;
    }
    if (step === "*" || Number.isInteger(parseInt(step))) {
      schemaToUpdate = schemaToUpdate.items;
    } else {
      if (schemaToUpdate) {
        schemaToUpdate = schemaToUpdate.properties[step];
      }
    }
  });
  return schemaToUpdate;
}
