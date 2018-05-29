const webpack = require('webpack');

module.exports = {
  devtool: 'source-map',
  externals: [
    /aws-sdk/,
    /electron/,
  ],
  target: 'node',
  module: {
    loaders: [{
      test: /\.js$/i,
      loader: 'babel-loader',
      exclude: [/node_modules/],
      query: {
        presets: [
          ['env', { targets: { node: '8.10' } }],
        ],
        plugins: [
          'transform-export-extensions',
          'transform-object-rest-spread',
          ['transform-runtime', { polyfill: false }],
        ],
      },
      rules: [{
        test: /\.js$/i,
        use: 'source-map-loader',
        enforce: 'pre',
      }],
    }],
  },
};

