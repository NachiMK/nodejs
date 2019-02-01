import pg from 'pg'
// the import order matters, we need pg types set first.
import Knex from 'knex'
import knexDialect from 'knex/lib/dialects/postgres'
require('dotenv').config()

pg.types.setTypeParser(20, 'text', parseInt)
pg.types.setTypeParser(1700, parseFloat)

const Query = 'SELECT CURRENT_TIMESTAMP AS "ServerCurrentTime"'
const { STAGE } = process.env
const dbConnString = process.env[`${STAGE}_ODSCONFIG_PG`]

export const pingodsdb = async (params = {}) => {
  console.log('Executing query to test DB..')
  console.log(`Query: ${Query}. Connection String: ${dbConnString}`)
  // may throw an error
  const knexPgClient = Knex({
    client: 'pg',
    connection: dbConnString,
    debug: true,
    pool: { min: 0, max: 1 },
  })
  knexPgClient.client = knexDialect
  const localKnex = knexPgClient
  try {
    console.log('About to run query...')
    const knexResp = await localKnex.raw(Query)
    if (knexResp && knexResp.rowCount >= 0) {
      console.log(`rows: ${JSON.stringify(knexResp.rows, null, 2)}`)
    }
    console.log('Completed running query:')
  } catch (err) {
    console.error(`'Error running pingdbTest: ${err.message}`)
  } finally {
    localKnex.destroy()
  }
  return 'pingodsdn completed.'
}
