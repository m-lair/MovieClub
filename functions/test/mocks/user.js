const { logError, logVerbose } = require("utilities");
const { firestore } = require("firestore");

async function populateUserData(params = {}) {
  logVerbose("Populating User data...")
  const testUserId = params.id || "test-user-id";
  const testUserData = {
    id: testUserId,
    name: params.name || "Test User",
    image: params.image || "Test Image",
    bio: params.bio || "Test Bio",
    email: params.email || "test@email.com"
  };
  try {
    await firestore.collection('users').doc(testUserId).set(testUserData);
    logVerbose("User data set");
  } catch (error) {
    logError("Error setting user data:", error);
  };

  return testUserData;
};

module.exports = { populateUserData }