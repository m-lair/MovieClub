'use strict';
require("module-alias/register");

const { db } = require('firestore');
  
db.settings({ host: 'localhost:8080', ssl: false });
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"