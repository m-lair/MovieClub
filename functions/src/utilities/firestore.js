const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const serviceAccountPath = path.join(__dirname, "service-account.json");

if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = require(serviceAccountPath);

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  }
} else {
  console.warn(`Service account key not found at ${serviceAccountPath}. Initializing with default credentials.`);

  if (!admin.apps.length) {
    admin.initializeApp();
  }
}

const db = admin.firestore();

module.exports = { admin, db };