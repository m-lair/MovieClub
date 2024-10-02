import * as functions from "firebase-functions";
import { firestore, firebaseAdmin } from "firestore";
import { handleCatchHttpsError, logError, logVerbose, throwHttpsError, verifyRequiredFields } from "helpers";
import { CreateUserWithEmailData, CreateUserWithOAuthData, UpdateUserData } from "./userTypes";

exports.createUserWithEmail = functions.https.onCall(async (data: CreateUserWithEmailData, context) => {
  try {
    const requiredFields = ["email", "name", "password"];
    verifyRequiredFields(data, requiredFields);

    const uid = await createUserAuthentication(data);

    if (uid) {
      await createUser(uid, data);
    }

    return uid;
  } catch (error: any) {
    handleCatchHttpsError("Error creating user:", error);
  }
});

exports.createUserWithSignInProvider = functions.https.onCall(async (data: CreateUserWithOAuthData, context) => {
  try {
    const requiredFields = ["email", "name", "signInProvider"];
    verifyRequiredFields(data, requiredFields);

    const userRecord = await getAuthUserByEmail(data.email);

    if (userRecord) {
      await createUser(userRecord.uid, data)
    } else {
      throwHttpsError("invalid-argument", `createUserWithSignInProvider: email does not exist`, data);
    }

    return userRecord?.uid;
  } catch (error: any) {
    handleCatchHttpsError("Error creating user:", error);
  }
});

// For email lookup, you can only search the main (top level) email and not provider specific emails. 
// For example, if a Facebook account with a different email facebookUser@example.com 
// is linked to an existing user with email user@example.com, 
// calling getUserByEmail("facebookUser@example.com") will yield no results 
// whereas getUserByEmail("user@example.com") will return the expected user. 
// In the case of the default "single account per email" setting, 
// the first email used to sign in with will be used as the top level email unless modified afterwards. 
// When "multiple accounts per email" is set, the main email is only set when a password user is created 
// unless manually updated.

async function getAuthUserByEmail(email: string) {
  try {
    return await firebaseAdmin.auth().getUserByEmail(email);
  } catch (error: any) {
    switch (error.code) {
      case 'auth/user-not-found':
        return null;

      default:
        throw error;
    };
  };
};

async function createUserAuthentication(data: CreateUserWithEmailData): Promise<string | undefined> {
  const { email, password, name } = data;

  try {
    const userRecord = await firebaseAdmin.auth().createUser({
      email: email,
      password: password,
      displayName: name
    });

    return userRecord.uid;
  } catch (error: any) {
    // all error codes: https://firebase.google.com/docs/auth/admin/errors
    switch (error.code) {
      case 'auth/email-already-exists':
        throwHttpsError("invalid-argument", error.message, data);

      case 'auth/invalid-display-name':
        throwHttpsError("invalid-argument", error.message, data);

      case 'auth/invalid-email':
        throwHttpsError("invalid-argument", error.message, data);

      case 'auth/invalid-password':
        throwHttpsError("invalid-argument", error.message, data);

      default:
        logError("Error creating admin user:", error);
        throwHttpsError("internal", `createUserAuthentication: ${error.message}`, data);
    };
  };
};

type CreateUserData = CreateUserWithEmailData & { signInProvider?: never } | CreateUserWithOAuthData;

async function createUser(id: string, data: CreateUserData): Promise<void> {
  const userData = {
    id: id,
    email: data.email,
    name: data.name,
    bio: data.bio || "",
    image: data.image || "",
    signInProvider: data.signInProvider || "",
    createdAt: firebaseAdmin.firestore.FieldValue.serverTimestamp()
  };

  try {
    await firestore.runTransaction(async (t) => {
      const userRefByName = firestore.collection("users").where('name', '==', data.name);
      const userRefByEmail = firestore.collection("users").where('email', '==', data.email);

      const [queryByName, queryByEmail] = await Promise.all([
        t.get(userRefByName),
        t.get(userRefByEmail)
      ]);

      if (queryByName.docs.length > 0) {
        throwHttpsError("invalid-argument", `name ${data.name} already exists.`, data);
      }

      if (queryByEmail.docs.length > 0) {
        throwHttpsError("invalid-argument", `email ${data.email} already exists.`, data);
      }

      const newUserRef = firestore.collection("users").doc(id);
      t.set(newUserRef, userData);
    });
  } catch (error: any) {
    switch (error.code) {
      case 'auth/invalid-password':
        throwHttpsError("invalid-argument", error.message);

      case 'invalid-argument':
        throw error;

      default:
        logError("Error creating user:", error);
        throwHttpsError("internal", `createUser: ${error.message}`, data);
    };
  };
};

exports.updateUser = functions.https.onCall(async (data: UpdateUserData, context): Promise<void> => {
  try {
    const requiredFields = ["id"];
    verifyRequiredFields(data, requiredFields);

    const userData = {
      ...(data.bio && { bio: data.bio }),
      ...(data.image && { image: data.image }),
      ...(data.name && { name: data.name })
    };

    await firestore.collection("users").doc(data.id).update(userData);

    logVerbose("User updated successfully!");
  } catch (error: any) {
    handleCatchHttpsError(`Error updating User ${data.id}`, error);
  };
});