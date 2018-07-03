import odsLogger from '../../../modules/log/ODSLogger';

export async function JsonToJsonSchema(event = {}) {
  ValidateParameter();
  const {
    TableName,
  } = event;
  try {
    odsLogger.log(`Processing JsonToJsonSchema for Table: ${TableName}`);
  } catch (err) {
    odsLogger.log('error', `Error Processing JsonToJsonSchema for Table: ${TableName}`, err.message);
  }
}

function ValidateParameter(event) {
  if (event) {
    if (!event.TableName) {
      throw new Error('Table Name is invalid.');
    }
  } else {
    throw new Error('Event details cannot be empty.');
  }
}
