// import pg from 'pg';
// the import order matters, we need pg types set first.
import Knex from 'knex';
import knexDialect from 'knex/lib/dialects/postgres';

const test = async () => {
  const retSingleValue = {
    scalarValue: '',
    completed: false,
    error: undefined,
  };
  try {
    console.log('testing knex');
    const cs = 'postgres://Nachi@localhost/postgres';
    const knexPgClient = Knex({
      client: 'pg',
      connection: cs,
      debug: true,
    });
    knexPgClient.client = knexDialect;
    const localKnex = knexPgClient;
    console.log('Calling knex');
    await localKnex.raw('SELECT CURRENT_TIMESTAMP as CT;')
      .then((resp1) => {
        if (resp1) {
          if (resp1.rows && (resp1.rows.length > 0)) {
            const value = Object.values(resp1.rows[0])[0];
            retSingleValue.scalarValue = value;
            retSingleValue.completed = true;
          }
        }
      })
      .catch((cresp) => {
        console.log(`Inside catch:${JSON.stringify(cresp, null, 2)}`);
      });
    console.log('Done with knex and then');
  } catch (err) {
    console.log(`knex error:${JSON.stringify(err, null, 2)}`);
    retSingleValue.scalarValue = undefined;
    retSingleValue.error = err;
    retSingleValue.completed = false;
  }
  console.log(`resp:${JSON.stringify(retSingleValue, null, 2)}`);
};
export { test as default };

console.log('test');
test();
