const dotenv = require('dotenv');

const env = process.env.NODE_ENV || "dev"
const config = require(`./config.${env}.js`);
require("./config.dev")

console.log(`Loaded ${env} configuration`);

module.exports = {
  config,
};