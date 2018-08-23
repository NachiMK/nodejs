import table from '@hixme/tables'

export async function getHistory(options = {}) {
  let { startDate = '', endDate = '' } = options
  const tableName = options.tableName

  if (startDate) {
    startDate = Date.now()
  }
  if (endDate) {
    endDate = Date.now()
  }

  // // TableName and IndexName come for free with @hixme/tables query
  // if (startDate && endDate) {
  //   params = Object.assign({}, addParams, {
  //     IndexName: 'HistoryCreated-index',
  //     FilterExpression: 'HistoryCreated BETWEEN :startDate AND :endDate',
  //     ExpressionAttributeValues: {
  //       ':startDate': startDate,
  //       ':endDate': endDate
  //     },
  //   })
  // }

  const historytable = createTable(tableName)

  const historyRows = await historytable.getAll()
  return historyRows
}

function createTable(tableName) {
  const stage = '' // process.env.stage;

  table.config({
    tablePrefix: stage,
    debug: false,
  })

  return table.create(tableName)
}

export async function getHistoryv1(options = {}) {
  const { tableName = '', eventDate = '' } = options
  console.log(`getHistoryv1: ${eventDate} not used.`)

  const historytable = createTable(tableName)

  const historyRows = await historytable.getAll()

  // in version 1 we had the history embeded so just extract those out.
  const normaliedrows = normalizeHistory(historyRows)

  // return
  return normaliedrows
}

// function createTable(table_name) {
//   const stage = process.env.stage;
//   table.config({
//     tablePrefix: stage,
//     debug: false,
//   });

//   return table.create(table_name);
// }

function normalizeHistory(rowToNormalize) {
  return rowToNormalize.map((e) => {
    const item = {
      HistoryId: e.Id,
      HistoryAction: e.eventName,
      HistoryDate: e.created.slice(0, 10).replace(/-/g, ''),
      HistoryCreated: e.created,
      Rowkey: e.key,
    }
    Object.assign(item, e.eventRecord)
    return item
  })
}

// export async function getAllPersonsForClient(clientPublicKey, options = {}) {
//   const {
//     activeOnly = true,
//     includeTestUsers = false,
//     projectionExpression = null,
//   } = options;

//   const personTable = createTable();
//   const params = {
//     ExpressionAttributeValues: { ':cpk': clientPublicKey },
//     IndexName: 'ClientPublicKey-index',
//     KeyConditionExpression: 'ClientPublicKey = :cpk',
//     ProjectionExpression: projectionExpression,
//   };

//   if (activeOnly) {
//     params.FilterExpression = 'IsActive = :isActive';
//     params.ExpressionAttributeValues[':isActive'] = activeOnly;
//   }

//   let persons = await personTable.query(params);
//   if (!includeTestUsers) {
//     persons = persons.filter(p => !p.IsTestUser);
//   }

//   return persons;
// }
