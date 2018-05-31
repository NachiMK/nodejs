import { isTableStatusActive, getTableRowCount } from '../table';
import { migrateHistory as dbMigrateHistory } from '../../../../data/dynamo/migratehistory';

export const migrateHistory = async (sourceTable, historyTable) => {
  const resp = {
    source_table: sourceTable,
    destination_table: historyTable,
    source_count: '',
    destination_count: '',
    migration_status: 'UNKNOWN',
  };
  const tblStatus = await isTableStatusActive(historyTable, false);
  const srcStatus = await isTableStatusActive(sourceTable, false);
  if ((tblStatus) && (srcStatus) && (tblStatus === true) && (srcStatus === true)) {
    // test
    const params = {
      source_table: sourceTable,
      destination_table: historyTable,
    };
    const dbresp = await dbMigrateHistory(params);
    if (dbresp) {
      resp.migration_status = 'COMPLETED';
      resp.source_count = dbresp.source_count;
      resp.destination_count = dbresp.destination_count;

      let tblcnt = await getTableRowCount(historyTable);
      tblcnt = (tblcnt === 0) ? dbresp.destination_count : tblcnt;
      resp.migration_status = (tblcnt === resp.source_count) ? 'SUCCESS' : 'INCOMPLETE';
    }
  }
  return resp;
};

// export const migrateAllv1HistoryTables = async (tableList = []) => {
//     //tableList.reduce()
//     return;
// }
