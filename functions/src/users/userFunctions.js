const functions = require("firebase-functions");
const { db, admin } = require("firestore");
const { handleCatchHttpsError, logError, logVerbose, throwHttpsError, verifyRequiredFields } = require("utilities");

exports.createUser = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["email", "name"];
    verifyRequiredFields(data, requiredFields)

    // Create the user in Firebase Authentication
    const uid = await createAdminUserAuthentication(data)

    // Prepare user data for Firestore
    await createUser(uid, data)

    return uid;
  } catch (error) {
    handleCatchHttpsError("Error creating user:", error)
  }
});

async function createAdminUserAuthentication({ email, password, name }) {
  try {
    // Check if user already exists
    // Client will create record if using alt signin method
    let userRecord = await admin.auth().getUserByEmail(email);

    if (userRecord) {
      return userRecord.uid
    }

    // Create user using email and password
    userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name
    });

    console.log(userRecord)

    return userRecord.uid
  } catch (error) {
    logError("Error creating admin user:", error)
    throwHttpsError("internal", `createAdminUserAuthentication: ${error.message}`);
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