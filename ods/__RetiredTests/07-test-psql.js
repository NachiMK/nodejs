import { executeQueryRS, executeScalar } from '../src/data/psql/index';

describe('Test psql', () => {
  it('Test Knex Scalar Query', async () => {
    console.log('Test Knex Scalar Query:');
    const p = {
      Query: 'SELECT CURRENT_TIMESTAMP AS CT;',
      DBName: 'PLANS',
      BatchKey: '1201',
    };
    const resp = await executeScalar(p);
    console.warn(`Result of Test Knex Scalar Query:${JSON.stringify(resp, null, 2)}`);
    expect(resp).toBeDefined();
  });

  it('Test Knex Recordset Query', async () => {
    console.log('Test Knex Recordset Query:');
    const p = {
      Query: 'SELECT CURRENT_TIMESTAMP AS CT;',
      DBName: 'PLANS',
      BatchKey: '1001',
    };
    const resp = await executeQueryRS(p);
    console.warn(`Result of Test Knex Recordset Query:${JSON.stringify(resp, null, 2)}`);
    expect(resp).toBeDefined();
  });
});
