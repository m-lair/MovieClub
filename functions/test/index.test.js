'use strict';

require("module-alias/register");

import { firestore } from 'firestore';
  
firestore.settings({ host: 'localhost:8080', ssl: false });
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"