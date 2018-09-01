export const DataPipeLineTaskConfigNameEnum = {
  DynamoDBtoS3: { value: 0, name: 'DynamoDB to S3', Parent: 0, ParentName: '' },
  ProcessJSONToPostgres: { value: 1, name: 'Process JSON to Postgres', Parent: 0, ParentName: '' },
  JSONHistoryDataToJSONSchema: {
    value: 2,
    name: 'JSON History Data to JSON Schema',
    Parent: 1,
    ParentName: 'ProcessJSONToPostgres',
  },
  JSONHistoryToFlatJSON: {
    value: 3,
    name: 'JSON History to Flat JSON',
    Parent: 1,
    ParentName: 'ProcessJSONToPostgres',
  },
  FlatJSONToCSV: {
    value: 4,
    name: 'Flat JSON to CSV',
    Parent: 1,
    ParentName: 'ProcessJSONToPostgres',
  },
  CSVToPrestage: {
    value: 5,
    name: 'CSV to Pre-stage',
    Parent: 1,
    ParentName: 'ProcessJSONToPostgres',
  },
  PreStagetoRAW: {
    value: 6,
    name: 'Pre-Stage to RAW',
    Parent: 1,
    ParentName: 'ProcessJSONToPostgres',
  },
  RAWToClean: { value: 7, name: 'RAW to Clean', Parent: 1, ParentName: 'ProcessJSONToPostgres' },
}

export function getTaskConfigParent(TaskConfigName) {
  let retVal
  try {
    if (TaskConfigName) {
      // do something
      const task = Object.keys(DataPipeLineTaskConfigNameEnum).find(
        (item) => DataPipeLineTaskConfigNameEnum[item].name === TaskConfigName
      )
      retVal = DataPipeLineTaskConfigNameEnum[task].ParentName
    }
  } catch (err) {
    retVal = ''
    console.error('Error finding parent', TaskConfigName)
  }
  return retVal
}

export const TaskStatusEnum = {
  OnHold: { Value: 10, name: 'On Hold' },
  Ready: { Value: 20, name: 'Ready' },
  HistoryCaptured: { Value: 30, name: 'History Captured' },
  Processing: { Value: 40, name: 'Processing' },
  Completed: { Value: 50, name: 'Completed' },
  Error: { Value: 60, name: 'Error' },
  ReProcess: { Value: 70, name: 'Re-Process' },
}
