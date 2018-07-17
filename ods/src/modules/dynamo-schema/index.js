import odsLogger from '../log/ODSLogger';

const awsSDK = require('aws-sdk');
const table = require('@hixme/tables');
const _ = require('lodash');
const generator = require('@hixme/generate-schema');

awsSDK.config.update({
  region: 'us-west-2',
  endpoint: 'https://dynamodb.us-west-2.amazonaws.com',
});

table.config({
  tablePrefix: '',
  debug: false,
  generateLengths: false,
  saveToFile: false,
});

export async function GetDynamoTableSchema(event = {}) {
  odsLogger.log(event);
  const retResp = {};
  try {
    const schema = generateTableSchema(event.TableName);
    if (schema && schema.length > 0) {
      retResp.Status = 'success';
      retResp.Schema = schema;
    }
  } catch (err) {
    retResp.Status = 'error';
    retResp.error = err;
    retResp.Schema = undefined;
  }
  return retResp;
}

const generateTableSchema = async (tableName, options = {}) => {
  const theTable = table.create(tableName);

  // this might take a while. TODO: Optimize this part.
  const data = await theTable.getAll().filter(b => typeof b.IsActive === 'undefined' || b.IsActive);
  let schemas = [];

  if (options.partitionKey) {
    const dataByPartition = _.groupBy(data, options.partitionKey);

    schemas = Object.keys(dataByPartition).map((key) => {
      const dataForPartition = dataByPartition[key];
      // Generate schema for each partition
      return generateSchemaByData(key, dataForPartition);
    });
  } else {
    const schema = generateSchemaByData(tableName, data);
    schemas.push(schema);
  }

  let schemString = '';
  schemas.forEach((s) => {
    schemString += JSON.stringify(s.schema);
  });

  return schemString;
};

function generateSchemaByData(name, data) {
  const schema = generator.json(name, data, {
    generateEnums: false,
    maxEnumValues: 0,
    generateLengths: false,
  });
  // Remove the array of items from top and just leave object
  return { name, schema: { $schema: schema.$schema, ...schema.items } };
}
