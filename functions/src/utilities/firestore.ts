import firebaseAdmin from "firebase-admin";
import fs from "fs";
import path from "path";

const serviceAccountPath = path.join(__dirname, "service-account.json");

if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = require(serviceAccountPath);

  if (!firebaseAdmin.apps.length) {
    firebaseAdmin.initializeApp({
      credential: firebaseAdmin.credential.cert(serviceAccount)
    });
  }
} else {
  console.warn(`Service account key not found at ${serviceAccountPath}. Initializing with default credentials.`);

  if (!firebaseAdmin.apps.length) {
    firebaseAdmin.initializeApp();
  }
}

const firestore = firebaseAdmin.firestore();

export { firebaseAdmin, firestore };