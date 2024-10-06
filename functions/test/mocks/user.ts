import { AuthData } from "firebase-functions/tasks";
import { logError, logVerbose } from "helpers";
import { firestore, firebaseAdmin } from "firestore";

export interface UserDataMock {
  id: string;
  bio: string;
  email: string;
  image: string;
  name: string;
  password: string;
  signInProvider: string;
  createdAt: number;
}

export interface UserDataAuth {
  user: UserDataMock;
  auth: AuthData;
}

type UserDataMockParams = Partial<UserDataMock> & {
  createUser?: boolean;
  createAuthUser?: boolean;
};

export async function populateUserData(
  params: UserDataMockParams = {},
): Promise<UserDataAuth> {
  logVerbose("Populating User data...");
  const { createUser = true, createAuthUser = true } = params;

  const testUserId = params?.id || "test-user-id";
  const testUserData: UserDataMock = {
    id: testUserId,
    bio: params.bio || "Test Bio",
    email: params.email || "test@email.com",
    image: params.image || "Test Image",
    name: params.name || "Test User",
    password: params.password || "TestPassword",
    signInProvider: params.signInProvider || "password",
    createdAt: Date.now(),
  };

  const authData = await authMock(testUserData);

  try {
    if (createAuthUser) {
      await firebaseAdmin.auth().createUser({
        email: testUserData.email,
        password: testUserData.password,
        displayName: testUserData.name,
      });
    }

    if (createUser) {
      await firestore.collection("users").doc(testUserId).set(testUserData);
    }
    logVerbose("User data set");
  } catch (error) {
    logError("Error setting user data:", error);
  }

  return { user: testUserData, auth: authData };
}

export function authMock(user: UserDataMock): AuthData {
  return {
    uid: user.id,
    token: {
      aud: process.env.PROJECT_ID!,
      auth_time: Date.now() - 99,
      email: user.email,
      email_verified: true,
      exp: Date.now() + 9999999,
      firebase: {
        identities: {},
        sign_in_provider: user.signInProvider,
      },
      iat: Date.now() - 99,
      iss: `https://securetoken.google.com/${process.env.PROJECT_ID}`,
      phone_number: "",
      picture: "",
      sub: user.id,
      uid: user.id,
    },
  };
}
