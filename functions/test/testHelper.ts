export const firebaseTest = require("firebase-functions-test")({
  projectId: process.env.PROJECT_ID,
  databaseURL: 'localhost:8080',
});

export async function clearDb() {
  try{
    await fetch(
      `http://localhost:8080/emulator/v1/projects/${process.env.PROJECT_ID}/databases/(default)/documents`,
      {
        method: 'DELETE',
      }
    );
  } catch (error) {
    throw error
  }
}

beforeEach(async function() {
 await clearDb()
});

afterEach(() => {
  firebaseTest.cleanup();
});