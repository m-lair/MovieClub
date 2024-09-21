'use strict';
require("module-alias/register");

const { db } = require('firestore');
  
db.settings({ host: 'localhost:8080', ssl: false });