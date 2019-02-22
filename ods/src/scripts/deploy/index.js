import { enableHistory, migrateHistory } from '../../service/dbadmin/index'

export const DeployEnableHistoryOnTables = async (envStage = '') => {
  console.log('Deploy History Streaming and Triggers for multiple tables:')
  const tbls = getTablesToDeploy(envStage)

  await asyncForEach(tbls, async (tablename) => {
    console.warn(`-----Table:${tablename}----`)
    console.warn(`-----Start:${Date.now}----`)
    const stageforFunc = envStage || process.env.STAGE
    const resp = await enableHistory(tablename, stageforFunc)
    console.warn(`Results ${JSON.stringify(resp, null, 2)}`)
    console.warn(`-----End:${Date.now}----`)
  })
}

export const DeployMigrateHistoryAllTables = async (envStage = '') => {
  console.log('Deploy - Migrate History from v1 to v2')
  const tbls = getTablesToMigrateHistory(envStage)
  await asyncForEach(tbls, async (tablename) => {
    console.warn(`Migrate History Table for:${tablename}`)
    console.warn(`-----Start:${Date.now}----`)
    // const stageforFunc = envStage || process.env.STAGE;
    let historyTableName
    if (tablename.endsWith('s')) {
      historyTableName = `${tablename.substring(0, tablename.length - 1)}-history`
    } else {
      historyTableName = `${tablename}-history`
    }
    const resp = await migrateHistory(historyTableName, `${tablename}-history-v2`)
    console.warn(`Results for table ${tablename}: ${JSON.stringify(resp, null, 2)}`)
    console.warn(`-----End:${Date.now}----`)
  })
}

const asyncForEach = async (array, callback) => {
  for (let index = 0; index < array.length; ) {
    await callback(array[index], index, array)
    index += 1
  }
}

export function getTablesToDeploy(envStage) {
  let retArray
  if (envStage) {
    if (envStage === 'prod') {
      retArray = [
        'prod-application-submission-workflows',
        'prod-benefit-change-events',
        'prod-benefits',
        'prod-bundle-event-offers',
        'prod-bundle-event-offers-log',
        'prod-bundle-events',
        'prod-carrier-messages',
        'prod-client-benefits',
        'prod-client-census',
        'prod-client-price-points',
        'prod-clients',
        'prod-enrollment-events',
        'prod-enrollment-questions',
        'prod-enrollment-responses',
        'prod-enrollments',
        'prod-locations',
        'prod-modeling-census',
        'prod-modeling-configuration',
        'prod-modeling-group-plans',
        'prod-modeling-price-points',
        'prod-modeling-scenarios',
        'prod-notes',
        'prod-payroll-deductions',
        'prod-persons',
        'prod-platform-authorization-events',
        'prod-prospect-census-models',
        'prod-prospect-census-profiles',
        'prod-prospects',
        'prod-tags',
        'prod-waived-benefits',
      ]
    } else if (envStage === 'int') {
      retArray = ['int-clients', 'int-ods-testtable-1']
      const retArray2 = [
        'int-benefit-change-events',
        'int-benefits',
        'int-bundle-event-offers',
        'int-bundle-event-offers-log',
        'int-bundle-events',
        'int-carrier-messages',
        'int-client-benefits',
        'int-client-census',
        'int-client-price-points',
        'int-clients',
        'int-enrollment-events',
        'int-enrollment-questions',
        'int-enrollment-responses',
        'int-enrollments',
        'int-locations',
        'int-modeling-census',
        'int-modeling-configuration',
        'int-modeling-group-plans',
        'int-modeling-price-points',
        'int-modeling-scenarios',
        'int-notes',
        'int-persons',
        'int-platform-authorization-events',
        'int-prospect-census-models',
        'int-prospect-census-profiles',
        'int-prospects',
        'int-tags',
        'int-waived-benefits',
      ]
    } else {
      retArray = [
        'dev-benefit-change-events',
        'dev-benefits',
        'dev-bundle-event-offers',
        'dev-bundle-event-offers-log',
        'dev-bundle-events',
        'dev-carrier-messages',
        'dev-client-benefits',
        'dev-client-census',
        'dev-client-price-points',
        'dev-clients',
        'dev-enrollment-events',
        'dev-enrollment-questions',
        'dev-enrollment-responses',
        'dev-enrollments',
        'dev-locations',
        'dev-modeling-census',
        'dev-modeling-configuration',
        'dev-modeling-group-plans',
        'dev-modeling-price-points',
        'dev-modeling-scenarios',
        'dev-notes',
        'dev-payroll-deductions',
        'dev-persons',
        'dev-platform-authorization-events',
        'dev-prospect-census-models',
        'dev-prospect-census-profiles',
        'dev-prospects',
        'dev-waived-benefits',
      ]
    }
  }
  return retArray
}

function getTablesToMigrateHistory(envStage) {
  let retArray
  if (envStage) {
    if (envStage === 'prod') {
      retArray = [
        'prod-application-submission-workflows',
        'prod-benefits',
        'prod-cart',
        'prod-client-benefits',
        'prod-clients',
        'prod-enrollments',
        'prod-notes',
        'prod-persons',
        'prod-prospect-census-profiles',
        'prod-prospects',
      ]
    } else if (envStage === 'int') {
      retArray = ['int-cart']
    } else {
      retArray = ['dev-cart']
    }
  }
  return retArray
}
