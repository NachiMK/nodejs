module.exports = {
  // entry: // set by the plugin
  // output: // set by the plugin
  devtool: 'source-map',
  externals: [
    /aws-sdk/,
    /electron/,
  ],
  target: 'node',
  // new config for webpack 4.x (via...)
  // https://github.com/goldwasserexchange/serverless-plugin-webpack
  // https://medium.com/webpack/webpack-4-mode-and-optimization-5423a6bc597a
  // https://github.com/babel/babel-preset-env/issues/186
  // https://www.valentinog.com/blog/webpack-4-tutorial/
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: 'babel-loader',
        query: {
          presets: [
            [
              'env',
              {
                targets: { node: '8.10' }, // Node version on AWS Lambda
                useBuiltIns: true,
                modules: false,
                loose: true,
              },
            ],
            'stage-0',
          ],
        },
      },
    ],
  },
  //
  // original config for webpack 3.x
  //
  // module: {
  //   loaders: [{
  //     test: /\.js$/i,
  //     loader: 'babel-loader',
  //     exclude: /node_modules/,
  //     query: {
  //       cacheDirectory: true,
  //       presets: [
  //         'es2017',
  //         'es2016',
  //         'es2015-node6',
  //       ],
  //       plugins: [
  //         'add-module-exports',
  //         'transform-class-properties',
  //         'transform-export-extensions',
  //         'transform-object-rest-spread',
  //       ],
  //     },
  //   }],
  // },
}
