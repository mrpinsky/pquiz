var path = require("path");
var webpack = require("webpack");
var merge = require('webpack-merge');
var CleanWebpackPlugin = require('clean-webpack-plugin');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');

const prod = 'production';
const dev = 'development';

// determine build env
const TARGET_ENV = process.env.npm_lifecycle_event === 'build' ? prod : dev;
const isDev = TARGET_ENV == dev;
const isProd = TARGET_ENV == prod;

const entryPath = "./src/app.js"

console.log("WEBPACK STARTED")
console.log("Building for", TARGET_ENV)

var commonConfig = {
  output: {
    path: path.resolve(__dirname, './dist'),
    filename: '[name].bundle.js',
  },
  module: {
    noParse: /\.elm$/,
  },
  plugins: [
    new CleanWebpackPlugin(['dist']),
    new HtmlWebpackPlugin({
      template: 'src/index.html',
      inject: 'body',
      filename: 'index.html',
    })
  ],
};

if (isDev) {
  module.exports = merge(commonConfig, {
    entry: [
      'webpack-dev-server/client?http://localhost:8080',
      entryPath
    ],
    devServer: {
      contentBase: './src/',
    },
    module: {
      rules: [{
        test: /\.elm$/,
        exclude: [/elm-suff/, /node_modules/],
        loader: 'elm-webpack-loader',
        options: {
          debug: true
        }
      },{
        test: /\.sc?ss$/,
        use: ['style-loader', 'css-loader', 'sass-loader']
      }]
    }
  });
}

if (isProd) {
  module.exports = merge(commonConfig, {
    entry: entryPath,
    module: {
      rules: [{
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: 'elm-webpack-loader',
      }, {
        test: /\.sc?ss$/,
        use: ExtractTextPlugin.extract({
          fallback: 'style-loader',
          use: ['css-loader', 'sass-loader']
        })
      }]
    },
    plugins: [
      new ExtractTextPlugin({
        filename: 'styles.css',
      }),

      // extract CSS into a separate file
      // minify JS
      new webpack.optimize.UglifyJsPlugin({
        minimize: true,
        compressor: {
          warnings: false
        }
      })
    ]
  });
}

