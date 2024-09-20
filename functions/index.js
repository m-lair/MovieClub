
const functions = require("firebase-functions");
const fetch = require("node-fetch");
// The Firebase Admin SDK to delete inactive users.
const admin = require("firebase-admin");

if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
// Export the scheduled function for deployment
exports.rotateMovie = functions.pubsub.schedule('every 24 hours').onRun(async () => {
    console.log('Rotating movie...');
    await rotateMovieLogic();
});
async function rotateMovieLogic() {
    const currentTimestamp = new Date();
    const apiEndpoint = `http://www.omdbapi.com/?apikey=${functions.config().omdbapi.key}&r=json`;

    const promises = [];

    try {
        const snapshot = await db.collectionGroup("movieclubs").get();
        snapshot.docs.forEach(doc => {
            const movieclub = doc.data();
            const clubInterval = movieclub.timeInterval;
            const futureDate = new Date(currentTimestamp.setDate(currentTimestamp.getDate() + clubInterval * 7));

            if (movieclub.movieEndDate <= currentTimestamp) {
                promises.push(processMovieClub(doc, futureDate, apiEndpoint));
            }
        });

        await Promise.all(promises);
    } catch (error) {
        console.error('Error rotating movies:', error);
    }
}

async function processMovieClub(movieclubDoc, futureDate, apiEndpoint) {
    const movieclub = movieclubDoc.data();
    const clubID = movieclubDoc.id;
    const nextUp = await movieclubDoc.ref.collection("members").orderBy("dateAdded", "asc").limit(1).get();
    const userID = nextUp.docs[0].id;
    const userDoc = await db.collection("users").doc(userID).get();
    const userData = userDoc.data();

    const membershipRef = await userDoc.ref.collection("memberships").doc(clubID).get();
    const membershipData = membershipRef.data();
    const movie = membershipData.queue[0];

    if (!movie) {
        return;
    }

    const response = await fetch(`${apiEndpoint}&t=${movie.title}`, { method: 'GET' });
    const data = await response.json();
    const newMovieData = {
        title: data.Title || 'No Title',
        director: data.Director || 'No Director',
        plot: data.Plot || 'No Plot',
        author: userData.name || 'no-name',
        authorID: userDoc.id || 'no-id',
        authorAvi: userData.image || 'no-image',
        created: new Date(),
        poster: data.Poster || 'no-image',
        endDate: futureDate,
        userName: userData.name || 'no-name',
    };

    await db.collection("movieclubs").doc(clubID).collection("movies").doc().set(newMovieData);
    await nextUp.docs[0].ref.update({ dateAdded: new Date() });
    await movieclubDoc.ref.update({ movieEndDate: futureDate });
}

exports.rotateMovieLogic = rotateMovieLogic;

exports.rotateMovie = functions.pubsub.schedule('every 24 hours').onRun(rotateMovieLogic);

exports.createUser = functions.https.onCall(async (data, context) => {

    // need whole thing to be promised
    // Check if the data contains the required fields
    if (!data.email || !data.password || !data.displayName) {
      throw new functions.https.HttpsError('invalid-argument', 'The function must be called with email, password, and displayName.');
    }
  
    try {
      // Create the user in Firebase Authentication
      try {
      const userRecord = await admin.auth().createUser({
        email: data.email,
        password: data.password,
        displayName: data.displayName
      });
      } catch (error) {
        console.error('Error creating user:', error);
        throw new functions.https.HttpsError('internal', 'Error creating user', error);
      }
      
      // Prepare user data for Firestore
      const userData = {
        uid: userRecord.uid,
        email: data.email,
        displayName: data.displayName,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      };

      try {
        // Add user data to Firestore
        await admin.firestore().collection('users').doc(userRecord.uid).set(userData);
      }catch (error) {
        console.error('Error signing in user:', error);
        throw new functions.https.HttpsError('internal', 'Error signing in user', error);
      }
  
      // Return the user ID
      return { uid: userRecord.uid };
    } catch (error) {
      console.error('Error creating new user:', error);
      throw new functions.https.HttpsError('internal', 'Error creating new user', error);
    }
  });