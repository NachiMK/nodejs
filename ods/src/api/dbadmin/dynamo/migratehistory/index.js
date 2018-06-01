import ware from 'warewolf';
// import path from 'path';
// import { validateParams } from '@hixme/validator-middleware';
import { before, after } from '@hixme/before-after-middleware';
import { migrateHistory } from '../../../../service/dbadmin/dynamo/migratehistory';
// import {isTableStatusActive} from '../../../../service/dbadmin/dynamo/table';
// require('../migratehistory/MigrateHistory.json');

export const MigrateHistory = ware(
  before,
  // validateParams(path.join(__dirname, 'MigrateHistory.json')),
  async (event) => {
    const dynamotablename = event.queryAndParams.DynamoTableName;
    const histTableName = `${dynamotablename}-history-v2`;
    const resp = await migrateHistory(dynamotablename, histTableName);
    event.result = resp;
  },
  after,
);

// export const MigrateAllv1History = ware(
//     before,
//     validateParams(path.join(__dirname, 'Migratev1TableHistory.json')),
//     async (event) => {
//         const tableList = event.queryAndParams.DynamoTables;
//     },
//     after,
// );
