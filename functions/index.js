
const functions = require("firebase-functions");
const fetch = require("node-fetch");
// The Firebase Admin SDK to delete inactive users.
const admin = require("firebase-admin");
const { DocumentReference } = require("firebase-admin/firestore");
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

            if (!movieclubDoc.exists) {
                throw new Error(`Movieclub with ID ${doc.id} does not exist.`);
            }
            const movieclubData = movieclubDoc.data();
            const clubID = doc.id;
            // get the next user in line by ordering the members by dateAdded and limiting to 1
            // this will be the next user to have their movie selected
            const nextUp = await movieclubDoc.ref.collection("members").orderBy("dateAdded", "asc").limit(1).get();
            // get user from doc
            const userID = nextUp.docs[0].id;
            const userRef = db.collection("users").doc(userID);
            console.log(`Next user in line is ${userID}`);
            const userDoc = await userRef.get();
            if (!userDoc.exists) {
                throw new Error(`User with ID ${userID} does not exist.`);
            }

            const userData = userDoc.data();
            console.log(clubID);
            const membershipRef = await userDoc.ref.collection("memberships").doc(clubID).get();

            if (!membershipRef.exists) {
                throw new Error(`Membership with ID ${clubID} does not exist.`);
            }
            const membershipData = membershipRef.data();
            const movie = membershipData.queue[0];

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
            const movieRef = db.collection("movieclubs").doc(clubID).collection("movies").doc().set(movieData);     
            try {
            resetDateAdded(membershipRef);
            } catch (error) {
                console.error(`Error resetting dateAdded for membership with ID ${membershipRef.id}:`, error);
            }
        });

        await Promise.all(promises);
    } catch (error) {
        console.error('Error rotating movies:', error);
    }
}

async function resetDateAdded(memberDoc) {
    memberDoc.update({ dateAdded: admin.firestore.Timestamp.now() });

}

exports.rotateMovieLogic = rotateMovieLogic;

exports.rotateMovie = functions.pubsub.schedule('every 24 hours').onRun(rotateMovieLogic);
