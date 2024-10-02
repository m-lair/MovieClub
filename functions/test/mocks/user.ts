import { logError, logVerbose } from "helpers";
import { firestore } from "firestore";
import { UserData } from "src/users/userTypes";

async function populateUserData(params: UserData): Promise<UserData> {
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