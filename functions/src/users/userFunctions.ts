<<<<<<< HEAD
<<<<<<< HEAD
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
  JoinMovieClubData,
  UpdateUserData,
} from "./userTypes";
import { CallableRequest } from "firebase-functions/https";
import {
  MEMBERS,
  MEMBERSHIPS,
  MOVIE_CLUBS,
  USERS,
} from "src/utilities/collectionNames";

exports.createUserWithEmail = functions.https.onCall(
  async (request: CallableRequest<CreateUserWithEmailData>) => {
    try {
      const { data } = request;
      const requiredFields = ["email", "name", "password"];
      verifyRequiredFields(request.data, requiredFields);

      const uid = await createUserAuthentication(request.data);
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
=======
import * as functions from "firebase-functions";
import { firestore, firebaseAdmin } from "firestore";
import { handleCatchHttpsError, logError, logVerbose, throwHttpsError, verifyRequiredFields } from "helpers";
import { CreateUserWithEmailData, CreateUserWithOAuthData, UpdateUserData } from "./userTypes";
import { CallableRequest } from "firebase-functions/https";

exports.createUserWithEmail = functions.https.onCall(async (request: CallableRequest<CreateUserWithEmailData>) => {
  try {
    const requiredFields = ["email", "name", "password"];
    verifyRequiredFields(request.data, requiredFields);

    const uid = await createUserAuthentication(request.data);

    if (uid) {
      await createUser(uid, request.data);
    }

    return uid;
  } catch (error: any) {
    handleCatchHttpsError("Error creating user:", error);
  }
});

exports.createUserWithSignInProvider = functions.https.onCall(async (request: CallableRequest<CreateUserWithOAuthData>) => {
  try {
    const requiredFields = ["email", "name", "signInProvider"];
    verifyRequiredFields(request.data, requiredFields);

    const userRecord = await getAuthUserByEmail(request.data.email);

    if (userRecord) {
      await createUser(userRecord.uid, request.data)
    } else {
      throwHttpsError("invalid-argument", `createUserWithSignInProvider: email does not exist`, request.data);
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
>>>>>>> 833179b (update to latest firebase-functions version)
// unless manually updated.

async function getAuthUserByEmail(email: string) {
  try {
    return await firebaseAdmin.auth().getUserByEmail(email);
  } catch (error: any) {
    switch (error.code) {
<<<<<<< HEAD
      case "auth/user-not-found":
=======
      case 'auth/user-not-found':
>>>>>>> 833179b (update to latest firebase-functions version)
        return null;

      default:
        throw error;
<<<<<<< HEAD
    }
  }
}

async function createUserAuthentication(
  data: CreateUserWithEmailData,
): Promise<string | undefined> {
=======
    };
  };
};

async function createUserAuthentication(data: CreateUserWithEmailData): Promise<string | undefined> {
>>>>>>> 833179b (update to latest firebase-functions version)
  const { email, password, name } = data;

  try {
    const userRecord = await firebaseAdmin.auth().createUser({
      email: email,
      password: password,
<<<<<<< HEAD
      displayName: name,
=======
      displayName: name
>>>>>>> 833179b (update to latest firebase-functions version)
    });

    return userRecord.uid;
  } catch (error: any) {
    // all error codes: https://firebase.google.com/docs/auth/admin/errors
    switch (error.code) {
<<<<<<< HEAD
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

type CreateUserData =
  | (CreateUserWithEmailData & { signInProvider?: never })
  | CreateUserWithOAuthData;
=======
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
>>>>>>> 833179b (update to latest firebase-functions version)

async function createUser(id: string, data: CreateUserData): Promise<void> {
  const userData = {
    id: id,
    email: data.email,
    name: data.name,
    bio: data.bio || "",
    image: data.image || "",
    signInProvider: data.signInProvider || "",
<<<<<<< HEAD
    createdAt: Date.now(),
=======
    createdAt: Date.now()
>>>>>>> 833179b (update to latest firebase-functions version)
  };

  try {
    await firestore.runTransaction(async (t) => {
<<<<<<< HEAD
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
=======
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
>>>>>>> 833179b (update to latest firebase-functions version)
      t.set(newUserRef, userData);
    });
  } catch (error: any) {
    switch (error.code) {
<<<<<<< HEAD
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
  },
);

exports.joinMovieClub = functions.https.onCall(
  async (request: CallableRequest<JoinMovieClubData>): Promise<void> => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = [
        "image",
        "movieClubId",
        "movieClubName",
        "username",
      ];
      verifyRequiredFields(data, requiredFields);

      const movieClubRef = await firestore
        .collection(MOVIE_CLUBS)
        .doc(data.movieClubId)
        .get();

      const movieClubData = movieClubRef.data();

      if (movieClubData !== undefined && !movieClubData.isPublic) {
        throwHttpsError(
          "permission-denied",
          "The Movie Club is not publicly joinable.",
        );
      }

      const userMembershipsRef = firestore
        .collection(USERS)
        .doc(uid)
        .collection(MEMBERSHIPS)
        .doc(data.movieClubId);

      await userMembershipsRef.set({
        movieClubName: data.movieClubName,
        createdAt: Date.now(),
      });

      const movieClubMemberRef = firestore
        .collection(MOVIE_CLUBS)
        .doc(data.movieClubId)
        .collection(MEMBERS)
        .doc(uid);

      await movieClubMemberRef.set({
        image: data.image,
        username: data.username,
        createdAt: Date.now(),
      });

      logVerbose("User updated successfully!");
    } catch (error: any) {
      handleCatchHttpsError(`Error joining movie club`, error);
    }
  },
);
=======
>>>>>>> d98a3c8 (working tests)
=======
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

exports.updateUser = functions.https.onCall(async (request: CallableRequest<UpdateUserData>): Promise<void> => {
  try {
    const requiredFields = ["id"];
    verifyRequiredFields(request.data, requiredFields);

    const userData = {
      ...(request.data.bio && { bio: request.data.bio }),
      ...(request.data.image && { image: request.data.image }),
      ...(request.data.name && { name: request.data.name })
    };

    await firestore.collection("users").doc(request.data.id).update(userData);

    logVerbose("User updated successfully!");
  } catch (error: any) {
    handleCatchHttpsError(`Error updating User ${request.data.id}`, error);
  };
});
>>>>>>> 833179b (update to latest firebase-functions version)
