const dotenv = require('dotenv').config();

const env = process.env.NODE_ENV || "dev";

let config;

try {
  config = require(`./config.${env}.js`);
  console.log(`Loaded ${env} configuration`);
} catch (error) {
  console.error(`Failed to load configuration for environment: ${env}`);
  console.error(error.message);
  config = {}; // Default to an empty object if no config file is found
}

module.exports = config;
