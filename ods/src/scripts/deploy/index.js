import { enableHistory, migrateHistory } from '../../service/dbadmin/index';

export const DeployEnableHistoryOnTables = async (envStage = '') => {
  console.log('Deploy History Streaming and Triggers for multiple tables:');
  const tbls = getTablesToDeploy(envStage);

  await asyncForEach(tbls, async (tablename) => {
    console.warn(`-----Table:${tablename}----`);
    console.warn(`-----Start:${Date.now}----`);
    const stageforFunc = envStage || process.env.STAGE;
    const resp = await enableHistory(tablename, stageforFunc);
    console.warn(`Results ${JSON.stringify(resp, null, 2)}`);
    console.warn(`-----End:${Date.now}----`);
  });
};

export const DeployMigrateHistoryAllTables = async (envStage = '') => {
  console.log('Deploy - Migrate History from v1 to v2');
  const tbls = getTablesToMigrateHistory(envStage);
  await asyncForEach(tbls, async (tablename) => {
    console.warn(`Migrate History Table for:${tablename}`);
    console.warn(`-----Start:${Date.now}----`);
    // const stageforFunc = envStage || process.env.STAGE;
    let historyTableName;
    if (tablename.endsWith('s')) {
      historyTableName = `${tablename.substring(0, tablename.length - 1)}-history`;
    } else {
      historyTableName = `${tablename}-history`;
    }
    const resp = await migrateHistory(historyTableName, `${tablename}-history-v2`);
    console.warn(`Results for table ${tablename}: ${JSON.stringify(resp, null, 2)}`);
    console.warn(`-----End:${Date.now}----`);
  });
};

const asyncForEach = async (array, callback) => {
  for (let index = 0; index < array.length;) {
    await callback(array[index], index, array);
    index += 1;
  }
};

export function getTablesToDeploy(envStage) {
  let retArray;
  if (envStage) {
    if (envStage === 'prod') {
      retArray = [
        'prod-application-submission-workflows',
        'prod-benefit-change-events',
        'prod-benefits',
        'prod-bundle-event-offers-log',
        'prod-carrier-messages',
        'prod-cart',
        'prod-client-benefits',
        'prod-client-census',
        'prod-client-contributions',
        'prod-clients',
        'prod-covered-hospitals',
        'prod-doctors',
        'prod-enrollment-responses',
        'prod-enrollments',
        'prod-locations',
        'prod-models',
        'prod-notes',
        'prod-payroll-deductions',
        'prod-persons',
        'prod-persons-attributes',
        'prod-prospect-census-models',
        'prod-prospect-census-profiles',
        'prod-prospects',
        'prod-tags',
        'prod-tobacco-factors-range',
      ];
    } else if (envStage === 'int') {
      retArray = [
        'int-cart',
        'int-persons',
      ];
    } else {
      retArray = [
        'dev-bundle-event-offers-log',
        'dev-carrier-messages',
        'dev-client-contributions',
        'dev-enrollment-responses',
        'dev-notes',
        'dev-payroll-deductions',
        'dev-persons-attributes',
        'dev-prospect-census-models',
        'dev-tobacco-factors-range',
      ];
      // retArray = [
      //   'dev-benefit-change-events',
      //   'dev-benefits',
      //   'dev-bundle-event-offers-log',
      //   'dev-carrier-messages',
      //   'dev-client-benefits',
      //   'dev-client-census',
      //   'dev-client-contributions',
      //   'dev-clients',
      //   'dev-doctors',
      //   'dev-enrollment-responses',
      //   'dev-enrollments',
      //   'dev-locations',
      //   'dev-notes',
      //   'dev-payroll-deductions',
      //   'dev-persons',
      //   'dev-persons-attributes',
      //   'dev-prospect-census-models',
      //   'dev-prospect-census-profiles',
      //   'dev-prospects',
      //   'dev-tobacco-factors-range',
      // ];
    }
  }
  return retArray;
}

function getTablesToMigrateHistory(envStage) {
  let retArray;
  if (envStage) {
    if (envStage === 'prod') {
      retArray = [
        'prod-application-submission-workflows',
        'prod-benefits',
        'prod-cart',
        'prod-client-benefits',
        'prod-clients',
        'prod-enrollments',
        'prod-models',
        'prod-notes',
        'prod-persons',
        'prod-prospect-census-profiles',
        'prod-prospects',
      ];
    } else if (envStage === 'int') {
      retArray = [
        'int-cart',
      ];
    } else {
      retArray = [
        'dev-cart',
        'dev-models',
      ];
    }
  }
  return retArray;
}
