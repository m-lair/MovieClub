const admin = require('firebase-admin');

// You need to set up your Firebase service account key.
const serviceAccount = require('./path-to-your-serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// db.settings({ host: 'localhost:8080', ssl: false });

module.exports = { admin, db };