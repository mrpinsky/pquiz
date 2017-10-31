var path = require("path");

var CleanWebpackPlugin = require('clean-webpack-plugin');

module.exports = {
  entry: {
    app: './src/app.js',
  },
  module: {
    rules: [
      {
        test: /\.html$/,
        exclude: /node_modules/,
        loader: 'file-loader?name=[name].[ext]',
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack-loader?verbose=true&warn=true',
      },
      {
        test: /\.scss$/,
        use: ['style-loader', 'css-loader', 'sass-loader'],
      },
    ],
    noParse: /\.elm$/,
  },
  plugins: [
    new CleanWebpackPlugin(['dist']),
  ],
  devServer: {
    contentBase: './dist',
  },
  output: {
    path: path.resolve(__dirname, '/dist'),
    filename: '[name].bundle.js',
  },
};
