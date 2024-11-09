import { firebaseAdmin } from "firestore";

export const firebaseTest = require("firebase-functions-test")({
  projectId: process.env.PROJECT_ID,
  databaseURL: "localhost:8080",
});

export async function clearDb() {
  await fetch(
    `http://localhost:8080/emulator/v1/projects/${process.env.PROJECT_ID}/databases/(default)/documents`,
    {
      method: "DELETE",
    },
  );
}

export async function clearAuthDb() {
  process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";

  const result = await firebaseAdmin.auth().listUsers();
  const users = result.users.map((user) => user.uid);

  await firebaseAdmin.auth().deleteUsers(users);
}
