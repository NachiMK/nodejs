import odsLogger from '../../../modules/log/ODSLogger';

export async function JsonToJsonNormalize(task = {}) {
  ValidateParameter(task);
  const {
    TableName,
  } = task;
  try {
    odsLogger.log('info', `Processing JsonToJsonNormalize for Table: ${TableName}`);
  } catch (err) {
    odsLogger.log('error', `Error Processing JsonToJsonNormalize for Table: ${TableName}`, err.message);
  }
}

function ValidateParameter(task) {
  if (task) {
    if (!task.TableName) {
      throw new Error('Table Name is invalid.');
    }
  } else {
    throw new Error('Event details cannot be empty.');
  }
}
