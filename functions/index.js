
const functions = require("firebase-functions");
// The Firebase Admin SDK to delete inactive users.
const admin = require("firebase-admin");
if (!admin.apps.length) {
    admin.initializeApp();
}

exports.rotateMovie = functions.pubsub.schedule('every 24 hours').onRun(async () => {
    console.log('Rotating movie...');
    await rotateMovieLogic();
});

// Export the scheduled function for deployment



async function rotateMovieLogic() {
    console.log('Rotating movie logic...');
    const db = admin.firestore();
    const apiEndpoint = `http://www.omdbapi.com/?apikey=${functions.config().omdbapi.key}&r=json`;
    const currentTimestamp = admin.firestore.Timestamp.now();
    try {
      const snapshot = await db.collectionGroup("movieclubs")
        .where("movieEndDate", "<", currentTimestamp)
        .get();
  
      const promises = snapshot.docs.map(async (doc) => {
        console.log(`Rotating movie for club ${doc.id}`);
            // if we are here then we know we have a club 
            // that has a movie that needs to be rotated

            // get movieclub from doc

            const movieclubDoc =  await doc.ref.get();

            const movie = [0];
            const clubID = doc.ref.parent.parent.id;
            const userID = doc.ref.parent.parent.parent.id;
            const clubRef = db.collection("movieclubs").doc(clubID);
            const userRef = db.collection("users").doc(userID);
            const userDoc = await userRef.get();
            if (!userDoc.exists) {
                throw new Error(`User with ID ${userID} does not exist.`);
            }
            const userData = userDoc.data();

            const response = await fetch(`${apiEndpoint}&t=${movie.title}`);
            if (!response.ok) {
                throw new Error(`Failed to fetch data for movie ${movie.title}`);
            }
            const data = await response.json();

            const movieData = {
                title: data.Title,
                director: data.Director,
                plot: data.Plot,
                author: userData.name,
                authorID: userData.id,
                authorAvi: userData.image,
                created: currentTimestamp,
                endDate: currentTimestamp + (1000 * 60 * 60 * 24 * 7)
            };

            
        });

        await Promise.all(promises);
    } catch (error) {
        console.error('Error rotating movies:', error);
    }
        
}

exports.rotateMovieLogic = rotateMovieLogic;

exports.rotateMovie = functions.pubsub.schedule('every 24 hours').onRun(rotateMovieLogic);
