const moment = require('moment');
const generator = require('generate-schema');
const Core = require('json-schema-library').cores.Draft04;
const isUUID = require('is-uuid');

module.exports.json = function json(title, object, options = {}) {
    options = Object.assign({}, { maxEnumValues: 20, generateEnums: false, generateLengths: false }, options);

    var schema = generator.json(title, object);
    addSchemaLimits(schema, object, options);
    return schema;
};

function addSchemaLimits(rootSchema, data, options) {

    const core = new Core(rootSchema);
    const stats = {};
    // Queue up the schema updates
    core.each(rootSchema, data, (schema, value, pointer) => {
        const schemaPointer = pointer.replace(/(\d+)/gi, '*').replace(' / ', ' - ');
        // Detect GUIDs and set min/max length to match data
        // Also detect formats: date-time, date
        if (typeof value !== 'object' && typeof value !== 'array') {
            const stat = stats[schemaPointer] || { schemaUpdateFunctions: [] };
            if (value.length === 36 && isUUID.anyNonNil(value)) {
                stat.schemaUpdateFunctions.push(s => {
                    s.minLength = 36;s.maxLength = 36;
                });
            } else if (moment(value, 'YYYY-MM-DD', true).isValid()) {
                stat.schemaUpdateFunctions.push(s => s.format = 'date');
            } else if (moment(value, moment.ISO_8601, true).isValid()) {
                stat.schemaUpdateFunctions.push(s => s.format = 'date-time');
            }

            if (schema.type === 'string') {
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
            stat.schemaUpdateFunctions.push(s => s.enum = Object.keys(stat.values).slice(0, options.maxEnumValues));
        }
        if (options.generateLengths && typeof stat.minLength !== 'undefined') {
            stat.schemaUpdateFunctions.push(s => {
                s.minLength = stat.minLength;
                s.maxLength = stat.maxLength;
            });
        }

        updateSchema(rootSchema, pointer, stat.schemaUpdateFunctions);
    });
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
    var steps = pointer.split('/');
    var schemaToUpdate = rootSchema;

    steps.forEach(step => {
        if (!schemaToUpdate) {
            console.log('Could not get schema for pointer', pointer);
            return;
        }
        if (step === '#') {
            return;
        }
        if (step === '*' || Number.isInteger(parseInt(step))) {
            schemaToUpdate = schemaToUpdate.items;
        } else {
            if (schemaToUpdate) {
                schemaToUpdate = schemaToUpdate.properties[step];
            }
        }
    });
    return schemaToUpdate;
}
//# sourceMappingURL=index.js.map