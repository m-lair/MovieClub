const functions = require("firebase-functions");
const { db } = require("firestore");
const { verifyRequiredFields } = require("utilities");

exports.createUser = functions.https.onCall(async (data, context) => {

  const requiredFields = ['email', 'displayName'];
  verifyRequiredFields(data, requiredFields)
  
  try {
    // Create the user in Firebase Authentication
    uid = await createAdminUserAuthentication(data)

    // Prepare user data for Firestore
    await createUser(uid, data)

    // Return the user ID
    return { uid: uid };
  } catch (error) {
    console.error('Error creating new user:', error);
    throw new functions.https.HttpsError('internal', 'Error creating new user', error);
  }
});

async function createAdminUserAuthentication({ email, password, displayName }) {
  try {
      // Check if user already exists
      // Client will create record if using alt signin method
      if (auth.getUserByEmail(email)) {
        const userRecord = auth.getUserByEmail(email);
        return userRecord.uid
      } 
      // Create user using email and password
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: displayName
      });
      return userRecord.uid
    
  } catch (error) {
    console.error('Error creating user:', error);
    throw new functions.https.HttpsError('internal', 'Error creating user', error);
  }
}

async function createUser(uid, { email, displayName }) {
  const userData = {
    uid: uid,
    email: email,
    displayName: displayName,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };

  try {
    // Add user data to Firestore
    await db.collection('users').doc(userRecord.uid).set(userData);
  } catch (error) {
    console.error('Error signing in user:', error);
    throw new functions.https.HttpsError('internal', 'Error signing in user', error);
  }
}