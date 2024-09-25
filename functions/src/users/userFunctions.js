const functions = require("firebase-functions");
const { db, admin } = require("firestore");
const { handleCatchHttpsError, logError, logVerbose, throwHttpsError, verifyRequiredFields } = require("utilities");

exports.createUser = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["email", "name"];
    verifyRequiredFields(data, requiredFields)

    // if the sign in provider is given, we've created the user already in auth and just need to retrieve the record
    // Maybe we separate these into two different routes?
    const userRecord = data.signInProvider ? await getAuthUserByEmail(data.email) : null;
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

async function createUserAuthentication(data) {
  const { email, password, name } = data

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
        throwHttpsError("invalid-argument", error.message, data);

      case 'auth/invalid-display-name':
        throwHttpsError("invalid-argument", error.message, data);

      case 'auth/invalid-email':
        throwHttpsError("invalid-argument", error.message, data);

      case 'auth/invalid-password':
        throwHttpsError("invalid-argument", error.message, data);

      default:
        logError("Error creating admin user:", error)
        throwHttpsError("internal", `createUserAuthentication: ${error.message}`, data);
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
    await db.runTransaction(async (t) => {
      const userRef = db.collection("users").where('name', '==', data.name);
      const query = await t.get(userRef);

      if (query.docs.length > 0) {
        throwHttpsError("invalid-argument", `name ${data.name} already exists.`, data);
      };

      const newUserRef = db.collection("users").doc(id);
      t.set(newUserRef, userData);
    });
  } catch (error) {
    switch (error.code) {
      case 'auth/invalid-password':
        throwHttpsError("invalid-argument", error.message);

      case 'invalid-argument':
        throw error

      default:
        logError("Error creating user:", error);
        throwHttpsError("internal", `createUser: ${error.message}`, data);
    };
  };
};

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