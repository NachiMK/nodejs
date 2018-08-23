const pg = require('pg')
module.exports = {
  dev: {
    client: 'postgres',
    connection: process.env.DEV_BUNDLE_PG,
  },
  int: {
    client: 'postgres',
    connection: process.env.INT_BUNDLE_PG,
  },
  prod: {
    client: 'postgres',
    connection: process.env.PROD_BUNDLE_PG,
  },
}
