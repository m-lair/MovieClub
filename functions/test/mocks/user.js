const { logVerbose } = require("utilities");
const { db } = require("firestore");

async function populateUserData(params = {}) {
  logVerbose("Populating User data...")
  const testUserId = params.id || "test-user-id";
  const testUserData = {
    id: testUserId,
    name: params.name || `Test User`,
    image: params.image || 'Test Image',
    bio: params.bio || 'Test Bio',
  };
  try {
    await db.collection('users').doc(testUserId).set(testUserData);
    logVerbose("User data set");
  } catch (error) {
    throw new Error(`Error setting user data: ${error}`);
  };

  return testUserData;
};

module.exports = { populateUserData }