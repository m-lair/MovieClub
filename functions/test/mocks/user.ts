import { logError, logVerbose } from "helpers";
import { firestore, firebaseAdmin } from "firestore";

export interface UserDataMock {
  id: string;
  bio: string;
  email: string;
  image: string;
  name: string;
  createdAt: string | firebaseAdmin.firestore.FieldValue;
};

type UserDataMockParams = Partial<UserDataMock>;

export async function populateUserData(params: UserDataMockParams = {}): Promise<UserDataMock> {
  logVerbose("Populating User data...");
  const testUserId = params?.id || "test-user-id";
  const testUserData: UserDataMock = {
    id: testUserId,
    bio: params.bio || "Test Bio",
    email: params.email || "test@email.com",
    image: params.image || "Test Image",
    name: params.name || "Test User",
    createdAt: firebaseAdmin.firestore.FieldValue.serverTimestamp()
  };
  try {
    await firestore.collection('users').doc(testUserId).set(testUserData);
    logVerbose("User data set");
  } catch (error) {
    logError("Error setting user data:", error);
  };

  return testUserData;
};
