const webpack = require("webpack")
module.exports = {
  entry: { 
	  "scripts/bundle.js" : "./coffeescript/entry.coffee" ,
  },
  output: {
    path: __dirname,
    filename: "[name]"
  },
  mode: "development",
  module: {
    rules: [
    { test: /\.coffee$/, loader: "coffee-loader" },
    ]
  }
};

