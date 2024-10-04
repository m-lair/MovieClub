import { firebaseAdmin } from "firestore";

export const firebaseTest = require("firebase-functions-test")({
  projectId: process.env.PROJECT_ID,
  databaseURL: 'localhost:8080',
});

async function clearDb() {
  await fetch(
    `http://localhost:8080/emulator/v1/projects/${process.env.PROJECT_ID}/databases/(default)/documents`,
    {
      method: 'DELETE',
    }
  );
}

async function clearAuthDb() {
  const result = await firebaseAdmin.auth().listUsers();
  const users = result.users.map(user => user.uid);
 
  await firebaseAdmin.auth().deleteUsers(users);
}

beforeEach(async () => {
 await clearDb()
 await clearAuthDb()
});

afterEach(async () => {
  firebaseTest.cleanup();
});
