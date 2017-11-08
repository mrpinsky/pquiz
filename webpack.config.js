var path = require("path");
var webpack = require("webpack");
var merge = require('webpack-merge');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var CleanWebpackPlugin = require('clean-webpack-plugin');

const prod = 'production';
const dev = 'development';

// determine build env
const TARGET_ENV = process.env.npm_lifecycle_event === 'build' ? prod : dev;
const isDev = TARGET_ENV == dev;
const isProd = TARGET_ENV == prod;

console.log("WEBPACK STARTED")
console.log("Building for", TARGET_ENV)

var commonConfig = {
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
      }
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
    path: path.resolve(__dirname, './dist'),
    filename: '[name].bundle.js',
  },
};

if (isDev) {
  module.exports = merge(commonConfig, {
    module: {
      rules: [{
        test: /\.elm$/,
        exclude: [/elm-suff/, /node_modules/],
        use: [{
          loader: 'elm-webpack-loader',
          options: {
            verbose: true,
            warn: true,
            debug: true
          }
        }]
      },{
        test: /\.sc?ss$/,
        use: ['style-loader', 'css-loader', 'sass-loader']
      }]
    }
  });
}

if (isProd) {
  module.exports = merge(commonConfig, {
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

