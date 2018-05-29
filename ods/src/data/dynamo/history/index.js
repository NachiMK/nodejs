import table from '@hixme/tables';

export async function getHistory(options = {}) {
  const {
    table_name = "",
    start_date = "",
    end_date = "",
  } = options;

  let params = ''
  if (start_date){
    start_date = Date.now();
  }
  if (end_date){
    end_date = Date.now();
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

  const historytable = createTable(table_name);

  const historyRows = await historytable.getAll();
  return historyRows;
}

function createTable(table_name) {
  const stage = "";//process.env.stage;

  table.config({
    tablePrefix: stage,
    debug: false,
  });

  return table.create(table_name);
}

export async function getHistoryv1(options = {}) {
  const {
    table_name = "",
    event_date = ""
  } = options;
  const historytable = createTable(table_name);

  const historyRows = await historytable.getAll();

  // in version 1 we had the history embeded so just extract those out.
  const normaliedrows = normalizeHistory(historyRows);

  //return
  return normaliedrows;
}

// function createTable(table_name) {
//   const stage = process.env.stage;
//   table.config({
//     tablePrefix: stage,
//     debug: false,
//   });

//   return table.create(table_name);
// }

function normalizeHistory(rows_to_normalize){
  return rows_to_normalize.map(e => {
      var item = {
        "HistoryId": e.Id,
        "HistoryAction": e.eventName,
        "HistoryDate": e.created.slice(0,10).replace(/-/g,""),
        "HistoryCreated":e.created,
        "Rowkey": e.key,
      };
      Object.assign(item, e.eventRecord);
      return item;
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
