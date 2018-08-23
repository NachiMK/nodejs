const webpack = require('webpack')

module.exports = {
  devtool: 'source-map',
  externals: {
    'aws-sdk': 'aws-sdk',
    electron: 'electron',
    sqlite3: 'sqlite3',
    mariasql: 'mariasql',
    mssql: 'mssql',
    mysql: 'mysql',
    mysql2: 'mysql2',
    oracle: 'oracle',
    'strong-oracle': 'strong-oracle',
    oracledb: 'oracledb',
    'pg-query-stream': 'pg-query-stream',
    'pg-native': 'pg-native',
  },
  target: 'node',
  module: {
    loaders: [
      {
        test: /\.js$/i,
        loader: 'babel-loader',
        exclude: [/node_modules/],
        query: {
          presets: [['env', { targets: { node: '8.10' } }]],
          plugins: [
            'transform-export-extensions',
            'transform-object-rest-spread',
            ['transform-runtime', { polyfill: false }],
          ],
        },
        rules: [
          {
            test: /\.js$/i,
            use: 'source-map-loader',
            enforce: 'pre',
          },
        ],
      },
    ],
  },
}
