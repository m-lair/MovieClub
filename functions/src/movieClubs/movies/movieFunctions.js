const functions = require("firebase-functions");
const fetch = require("node-fetch");
const { db } = require("firestore");

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
  const clubId = movieclubDoc.id;
  const nextUp = await movieclubDoc.ref.collection("members").orderBy("dateAdded", "asc").limit(1).get();
  const userId = nextUp.docs[0].id;
  const userDoc = await db.collection("users").doc(userId).get();
  const userData = userDoc.data();

  const membershipRef = await userDoc.ref.collection("memberships").doc(clubId).get();
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
    authorId: userDoc.id || 'no-id',
    authorAvi: userData.image || 'no-image',
    created: new Date(),
    poster: data.Poster || 'no-image',
    endDate: futureDate,
    userName: userData.name || 'no-name',
  };

  await db.collection("movieclubs").doc(clubId).collection("movies").doc().set(newMovieData);
  await nextUp.docs[0].ref.update({ dateAdded: new Date() });
  await movieclubDoc.ref.update({ movieEndDate: futureDate });
}

exports.rotateMovieLogic = rotateMovieLogic;

exports.rotateMovie = functions.pubsub.schedule('every 24 hours').onRun(rotateMovieLogic);
