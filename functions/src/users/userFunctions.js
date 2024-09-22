const functions = require("firebase-functions");
const { db, admin } = require("firestore");
const { handleCatchHttpsError, logError, logVerbose, throwHttpsError, verifyRequiredFields } = require("utilities");

exports.createUser = functions.https.onCall(async (data, context) => {

  const requiredFields = ["email", "name"];
  verifyRequiredFields(data, requiredFields)

  // need whole thing to be promised

  try {
    // Create the user in Firebase Authentication
    const uid = await createAdminUserAuthentication(data)

    // Prepare user data for Firestore
    await createUser(uid, data)

    // Return the user ID
    return uid;
  } catch (error) {
    handleCatchHttpsError("Error creating user:", error)
  }
});

async function createAdminUserAuthentication({ email, password, name }) {
  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name
    });

    return userRecord.uid
  } catch (error) {
    logError("Error creating admin user:", error)
    throwHttpsError("internal", `createAdminUserAuthentication: ${error.message}`);
  }
}

async function createUser(uid, data = { email, name, signInProvider }) {
  const userData = {
    uid: uid,
    email: email,
    name: name,
    signInProvider: signInProvider,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };

  try {
    await db.collection("users").doc(userRecord.uid).set(userData);
  } catch (error) {
    logError("Error creating user:", error)
    throwHttpsError("internal", `createUser: ${error.message}`, data);
  }
}

exports.updateUser = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["uid"];
    verifyRequiredFields(data, requiredFields);

    const userData = {
      ...(data.bio && { bio: data.bio }),
      ...(data.email && { email: data.email }),
      ...(data.image && { image: data.image }),
      ...(data.name && { name: data.name }),
      ...(data.signInProvider && { signInProvider: data.signInProvider }),
    };

    await db.collection("users").doc(data.uid).update(userData);

    logVerbose("User updated successfully!");
  } catch (error) {
    handleCatchHttpsError(`Error updating User ${data.uid}`, error)
  };
});