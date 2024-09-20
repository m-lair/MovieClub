const dotenv = require('dotenv');

const env = process.env || "dev"
const config = require(`./config.${env}.js`);

console.log(`Loaded ${env} configuration`);

module.exports = {
  config,
};