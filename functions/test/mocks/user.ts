import { logError, logVerbose } from "helpers";
import { firestore } from "firestore";
import { UpdateUserData } from "src/users/userTypes";

async function populateUserData(params: UpdateUserData): Promise<UpdateUserData> {
  logVerbose("Populating User data...")
  const testUserId = params.id || "test-user-id";
  const testUserData: UpdateUserData = {
    id: testUserId,
    bio: params.bio || "Test Bio",
    email: params.email || "test@email.com",
    image: params.image || "Test Image",
    name: params.name || "Test User",
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