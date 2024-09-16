
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
    console.log('Rotating movie logic...');
    console.log('after getting db' + db);
    const apiEndpoint = `http://www.omdbapi.com/?apikey=${functions.config().omdbapi.key}&r=json`;
    console.log('apiEndpoint: ' + apiEndpoint);

    try {
      console.log('getting snapshot');
      /*const snapshot = await db.collectionGroup("movieclubs")
        .where("movieEndDate", "<", currentTimestamp)
        .get();*/
      const snapshot = await db.collectionGroup("movieclubs").get();
      console.log('snapshot COUNT: ' + snapshot.docs.length);
      const promises = snapshot.docs.map(async (doc) => {
        console.log(`Rotating movie for club ${doc.id}`);
            // if we are here then we know we have a club 
            // that has a movie that needs to be rotated
            const currentTimestamp = new Date();

            // get movieclub from doc
            console.log('currentTimestamp: ' + currentTimestamp);
            console.log('movieEndDate: ' + doc.data().movieEndDate);
            if(doc.data().movieEndDate <= currentTimestamp){
                console.log('movieEndDate < currentTimestamp');
            
            const movieclubDoc =  await doc.ref.get();

            const clubInterval =  movieclubDoc.data().timeInterval;
            const futureDate = new Date(currentTimestamp.setDate(currentTimestamp.getDate() + clubInterval * 7));
            console.log("futureDate: " + futureDate);
            if (!movieclubDoc.exists) {
                throw new Error(`Movieclub with ID ${doc.id} does not exist.`);
            }
            const clubID = doc.id;
            // get the next user in line by ordering the members by dateAdded and limiting to 1
            // this will be the next user to have their movie selected
            const nextUp = await movieclubDoc.ref.collection("members").orderBy("dateAdded", "asc").limit(1).get();
            // get user from doc
            if (nextUp.docs.length === 0) {
                throw new Error(`No users in line for club ${clubID}`);
            }
            const userID = nextUp.docs[0].id;
            const userDoc = await db.collection("users").doc(userID).get();
            if (!userDoc.exists) {
                throw new Error(`User with ID ${userID} does not exist.`);
            }

            const userData = userDoc.data();

            console.log('userData: ' + userData.name);
            console.log('userID: ' + userID);
            
            membershipRef = await userDoc.ref.collection("memberships").doc(clubID).get();
            console.log('membershipRef: ' + membershipRef.data());
         
            if (!membershipRef.exists) {
                throw new Error(`Membership with ID ${clubID} does not exist.`);
            }
            const membershipData = membershipRef.data();
            if(membershipData.queue.length === 0){
                throw new Error(`No movies in queue for user ${userData.name}`);
            }
            const movie = membershipData.queue[0];

            console.log('movie: ' + movie.title);
            const response = await fetch(`${apiEndpoint}&t=${movie.title}`, { method: 'GET' });
            console.log('response: ' + response);
            if (!response.ok) {
                throw new Error(`Failed to fetch data for movie ${movie.title}`);
            }

            const data = await response.json();
            if (!data) {
                throw new Error(`No data found for movie ${movie.title}`); 
            }
            const newMovieData = {
                title: data.Title ? data.Title : 'No Title',
                director: data.Director ? data.Director : 'No Director',
                plot: data.Plot ? data.Plot : 'No Plot',
                author: userData.name ? userData.name : 'no-name',
                authorID: userDoc.id ? userDoc.id : 'no-id',
                authorAvi: userData.image ? userData.image : 'no-image',
                created: currentTimestamp,
                poster: data.Poster ? data.Poster : 'no-image',
                endDate: futureDate,
                userName: userData.name ? userData.name : 'no-name',
            };   

            console.log('newMovieData: ' + newMovieData);

            db.collection("movieclubs").doc(clubID).collection("movies").doc().set(newMovieData);     
            try {
            nextUp.docs[0].ref.update({ dateAdded: currentTimestamp });
            movieclubDoc.ref.update({ movieEndDate: futureDate });
            } catch (error) {
                console.error(`Error resetting dateAdded for membership with ID ${membershipRef.id}:`, error);
            }
          }
        });

        await Promise.all(promises);
    } catch (error) {
        console.error('Error rotating movies:', error);
    }
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