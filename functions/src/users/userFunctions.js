const functions = require("firebase-functions");
const { db, admin } = require("firestore");
const { handleCatchHttpsError, logError, logVerbose, throwHttpsError, verifyRequiredFields } = require("utilities");

exports.createUser = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["email", "name"];
    verifyRequiredFields(data, requiredFields)

    // try to find an auth user by their email or create an auth record
    const userRecord = await getAuthUserByEmail(data.email)
    const uid = userRecord?.uid || await createUserAuthentication(data);

    await createUser(uid, data)

    return uid;
  } catch (error) {
    handleCatchHttpsError("Error creating user:", error)
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

async function getAuthUserByEmail(email) {
  try {
    return await admin.auth().getUserByEmail(email);
  } catch (error) {
    switch (error.code) {
      case 'auth/user-not-found':
        return null;

      default:
        throw error;
    }
  }
}

async function createUserAuthentication({ email, password, name }) {
  try {
    userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name
    });

    return userRecord.uid
  } catch (error) {
    // all error codes: https://firebase.google.com/docs/auth/admin/errors
    switch (error.code) {
      case 'auth/email-already-exists':
        throwHttpsError("invalid-argument", error.message);

      case 'auth/invalid-display-name':
        throwHttpsError("invalid-argument", error.message);

      case 'auth/invalid-email':
        throwHttpsError("invalid-argument", error.message);

      case 'auth/invalid-password':
        throwHttpsError("invalid-argument", error.message);

      default:
        logError("Error creating admin user:", error)
        throwHttpsError("internal", `userFunctions.createUserAuthentication: ${error.message}`);
    }
  }
}

async function createUser(id, data) {
  const userData = {
    id: id,
    email: data.email,
    name: data.name,
    bio: data.bio || "",
    image: data.image || "",
    signInProvider: data.signInProvider || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };

  try {
    await db.collection("users").doc(id).set(userData);
  } catch (error) {
    logError("Error creating user:", error)
    throwHttpsError("internal", `createUser: ${error.message}`, data);
  }
}

exports.updateUser = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["id"];
    verifyRequiredFields(data, requiredFields);

    const userData = {
      ...(data.bio && { bio: data.bio }),
      ...(data.email && { email: data.email }),
      ...(data.image && { image: data.image }),
      ...(data.name && { name: data.name }),
      ...(data.signInProvider && { signInProvider: data.signInProvider }),
    };

    await db.collection("users").doc(data.id).update(userData);

    logVerbose("User updated successfully!");
  } catch (error) {
    handleCatchHttpsError(`Error updating User ${data.id}`, error)
  };
});