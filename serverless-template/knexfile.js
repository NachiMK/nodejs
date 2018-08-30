require('dotenv').config();

module.exports = {
  // Optionally, you can specify a local sqlite or pg db
  // dev: {
  //   client: 'sqlite3',
  //   useNullAsDefault: true,
  //   connection: {
  //     filename: './example.db',
  //   },
  // },
  dev: {
    client: 'postgres',
    connection: process.env.DEV_SERVERLESS_PG,
    pool: {
      min: 2,
      max: 10,
    },
    debug: true,
  },
  int: {
    client: 'postgres',
    connection: process.env.INT_SERVERLESS_PG,
    pool: {
      min: 2,
      max: 10,
    },
    debug: true,
  },
  prod: {
    client: 'postgres',
    connection: process.env.PROD_SERVERLESS_PG,
    pool: {
      min: 2,
      max: 10,
    },
  },
};
