import * as functions from "firebase-functions";
import { firestore, firebaseAdmin } from "firestore";
import {
  handleCatchHttpsError,
  logError,
  logVerbose,
  throwHttpsError,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import {
  CreateUserWithEmailData,
  CreateUserWithOAuthData,
  DeleteUserData,
  UpdateUserData,
} from "./userTypes";
import { CallableRequest } from "firebase-functions/https";
import { USERS } from "src/utilities/collectionNames";

exports.deleteUser = functions.https.onCall(
  async (request: CallableRequest<DeleteUserData>) => {
    try {
      const { auth } = request;
      const { uid } = verifyAuth(auth);

      // Anonymize and soft-delete the user document
      await anonymizeUserDocument(uid);
      logVerbose(`User document ${uid} anonymized and soft-deleted.`);

      // Update related data in 'movieclubs' collection
      await anonymizeMovieClubsForUser(uid);
      logVerbose(`Related data in 'movieclubs' collection updated.`);

      // Optionally, sign out the user from Firebase Authentication
      await firebaseAdmin.auth().revokeRefreshTokens(uid);
      logVerbose(`Refresh tokens revoked for user ${uid}.`);

      // Optionally, delete the user from Firebase Authentication
      await firebaseAdmin.auth().deleteUser(uid);
      // logVerbose(`User ${uid} deleted from Firebase Authentication.`);
    } catch (error: any) {
      handleCatchHttpsError(`Error soft-deleting user ${request.auth?.uid}:`, error);
    }
  }
);

/**
 * Anonymizes related data in the 'movieclubs' collection for the deleted user.
 *
 * @param userId The UID of the user to anonymize.
 */
async function anonymizeMovieClubsForUser(userId: string): Promise<void> {
  const movieClubsRef = firestore.collection('movieclubs');

  // Update 'ownerId' and 'ownerName' in 'movieclubs' documents
  await updateMovieClubsOwnerData(movieClubsRef, userId);

  // Update subcollections recursively
  await updateMovieClubsSubcollections(movieClubsRef, userId);
}

/**
 * Updates 'ownerId' and 'ownerName' in 'movieclubs' documents where the user is the owner.
 *
 * @param movieClubsRef Reference to the 'movieclubs' collection.
 * @param userId The UID of the user to anonymize.
 */
async function updateMovieClubsOwnerData(
  movieClubsRef: FirebaseFirestore.CollectionReference,
  userId: string
): Promise<void> {
  let query = movieClubsRef.where('ownerId', '==', userId).limit(500);
  let snapshot = await query.get();

  while (!snapshot.empty) {
    const batch = firestore.batch();

    snapshot.docs.forEach(doc => {
      const docRef = doc.ref;
      batch.update(docRef, {
        ownerId: '[deleted user]',
        ownerName: '[deleted user]',
      });
    });

    await batch.commit();

    // Prepare for the next batch
    const lastDoc = snapshot.docs[snapshot.docs.length - 1];
    query = movieClubsRef
      .where('ownerId', '==', userId)
      .startAfter(lastDoc)
      .limit(500);

    snapshot = await query.get();
  }
}

/**
 * Updates subcollections of 'movieclubs' documents where 'userId' matches the deleted user.
 *
 * @param movieClubsRef Reference to the 'movieclubs' collection.
 * @param userId The UID of the user to anonymize.
 */
async function updateMovieClubsSubcollections(
  movieClubsRef: FirebaseFirestore.CollectionReference,
  userId: string
): Promise<void> {
  const movieClubsSnapshot = await movieClubsRef.get();

  for (const clubDoc of movieClubsSnapshot.docs) {
    await anonymizeSubcollections(clubDoc.ref, userId);
  }
}

/**
 * Recursively anonymizes subcollections where 'userId' matches the deleted user.
 *
 * @param docRef Reference to the document.
 * @param userId The UID of the user to anonymize.
 */
async function anonymizeSubcollections(
  docRef: FirebaseFirestore.DocumentReference,
  userId: string
): Promise<void> {
  const subcollections = await docRef.listCollections();

  for (const subcollection of subcollections) {
    let query = subcollection.where('userId', '==', userId).limit(500);
    let snapshot = await query.get();

    while (!snapshot.empty) {
      const batch = firestore.batch();

      snapshot.docs.forEach(doc => {
        const docRef = doc.ref;
        const updateData: any = {
          userId: '[deleted user]',
          userName: '[deleted user]',
        };

        // If the subcollection is 'comments', nullify the 'text' attribute
        if (subcollection.id === 'comments') {
          updateData.text = null;
        }

        batch.update(docRef, updateData);
      });

      await batch.commit();

      // Prepare for the next batch
      const lastDoc = snapshot.docs[snapshot.docs.length - 1];
      query = subcollection
        .where('userId', '==', userId)
        .startAfter(lastDoc)
        .limit(500);

      snapshot = await query.get();
    }

    // Recursively process nested subcollections
    for (const doc of snapshot.docs) {
      await anonymizeSubcollections(doc.ref, userId);
    }
  }
}

/**
 * Anonymizes and soft-deletes the user document in the 'USERS' collection.
 *
 * @param userId The UID of the user to anonymize.
 */
async function anonymizeUserDocument(userId: string): Promise<void> {
  const userRef = firestore.collection(USERS).doc(userId);

  const anonymizedData = {
    email: firebaseAdmin.firestore.FieldValue.delete(),
    name: "[deleted user]",
    bio: firebaseAdmin.firestore.FieldValue.delete(),
    image: firebaseAdmin.firestore.FieldValue.delete(),
    signInProvider: firebaseAdmin.firestore.FieldValue.delete(),
    isDeleted: true,
    deletedAt: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
  };

  await userRef.update(anonymizedData);
}

exports.createUserWithEmail = functions.https.onCall(
  async (request: CallableRequest<CreateUserWithEmailData>) => {
    try {
      const { data } = request;
      const requiredFields = ["email", "name", "password"];
      verifyRequiredFields(data, requiredFields);

      const uid = await createUserAuthentication(data);
      data.signInProvider = "password";

      if (uid) {
        await createUser(uid, data);
      }

      return uid;
    } catch (error: any) {
      handleCatchHttpsError("Error creating user:", error);
    }
  },
);

exports.createUserWithSignInProvider = functions.https.onCall(
  async (request: CallableRequest<CreateUserWithOAuthData>) => {
    try {
      const { data, auth } = request;
      const {
        uid,
        token: {
          email,
          firebase: { sign_in_provider },
        },
      } = verifyAuth(auth);

      const requiredFields = ["name"];
      verifyRequiredFields(data, requiredFields);

      const userRecord = await getAuthUserByEmail(email!);
      data.signInProvider = sign_in_provider;

      if (userRecord) {
        await createUser(uid, data);
      } else {
        throwHttpsError(
          "invalid-argument",
          `createUserWithSignInProvider: email does not exist`,
          data,
        );
      }

      return uid;
    } catch (error: any) {
      handleCatchHttpsError("Error creating user:", error);
    }
  },
);

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
      case "auth/user-not-found":
        return null;

      default:
        throw error;
    }
  }
}

async function createUserAuthentication(
  data: CreateUserWithEmailData,
): Promise<string | undefined> {
  const { email, password, name } = data;

  try {
    const userRecord = await firebaseAdmin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    return userRecord.uid;
  } catch (error: any) {
    // all error codes: https://firebase.google.com/docs/auth/admin/errors
    switch (error.code) {
      case "auth/email-already-exists":
        throwHttpsError("invalid-argument", error.message, data);
        break;
      case "auth/invalid-display-name":
        throwHttpsError("invalid-argument", error.message, data);
        break;
      case "auth/invalid-email":
        throwHttpsError("invalid-argument", error.message, data);
        break;
      case "auth/invalid-password":
        throwHttpsError("invalid-argument", error.message, data);
        break;
      default:
        logError("Error creating admin user:", error);
        throwHttpsError(
          "internal",
          `createUserAuthentication: ${error.message}`,
          data,
        );
    }
  }
}

type CreateUserData = CreateUserWithEmailData | CreateUserWithOAuthData;

async function createUser(id: string, data: CreateUserData): Promise<void> {
  const userData = {
    id: id,
    email: data.email,
    name: data.name,
    bio: data.bio || "",
    image: data.image || "",
    signInProvider: data.signInProvider || "",
    createdAt: Date.now(),
  };

  try {
    await firestore.runTransaction(async (t) => {
      const userRefByName = firestore
        .collection(USERS)
        .where("name", "==", data.name);
      const userRefByEmail = firestore
        .collection(USERS)
        .where("email", "==", data.email);

      const [queryByName, queryByEmail] = await Promise.all([
        t.get(userRefByName),
        t.get(userRefByEmail),
      ]);

      if (queryByName.docs.length > 0) {
        throwHttpsError(
          "invalid-argument",
          `name ${data.name} already exists.`,
          data,
        );
      }

      if (queryByEmail.docs.length > 0) {
        throwHttpsError(
          "invalid-argument",
          `email ${data.email} already exists.`,
          data,
        );
      }

      const newUserRef = firestore.collection(USERS).doc(id);
      t.set(newUserRef, userData);
    });
  } catch (error: any) {
    switch (error.code) {
      case "auth/invalid-password":
        throwHttpsError("invalid-argument", error.message);
        break;
      case "invalid-argument":
        throw error;
      default:
        logError("Error creating user:", error);
        throwHttpsError("internal", `createUser: ${error.message}`, data);
    }
  }
}

exports.updateUser = functions.https.onCall(
  async (request: CallableRequest<UpdateUserData>): Promise<void> => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const userData = {
        ...(data.bio && { bio: data.bio }),
        ...(data.image && { image: data.image }),
        ...(data.name && { name: data.name }),
      };

      await firestore.collection(USERS).doc(uid).update(userData);

      logVerbose("User updated successfully!");
    } catch (error: any) {
      handleCatchHttpsError(`Error updating User ${request.auth?.uid}`, error);
    }
  }
);

exports.updateUserProfileImage = functions.https.onCall(
  async (request: CallableRequest<{ imageUrl: string }>): Promise<void> => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);

      // Verify the image URL is from our stock images bucket
      if (!data.imageUrl.includes('stockimages')) {
        throwHttpsError(
          "invalid-argument",
          "Invalid image URL. Must be from stock images.",
          data
        );
      }

      await firestore.collection(USERS).doc(uid).update({
        image: data.imageUrl
      });

      logVerbose("User profile image updated successfully!");
    } catch (error: any) {
      handleCatchHttpsError(`Error updating user profile image ${request.auth?.uid}`, error);
    }
  }
);
