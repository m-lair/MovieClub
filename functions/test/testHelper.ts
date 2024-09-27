const test = require("firebase-functions-test")({
  projectId: process.env.PROJECT_ID,
  databaseURL: 'localhost:8080',
});

async function clearDb() {
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
  test.cleanup();
});

module.exports = { test, clearDb }