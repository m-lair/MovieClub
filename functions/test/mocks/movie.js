const { logError, logVerbose } = require("helpers");
const { firestore, firebaseAdmin } = require("firestore");

async function populateMovieData(params = {}) {
  logVerbose("Populating movie data...");
  const MoviceClubId = params.movieClubId || "test-club";
  const movieId = params.id || "test-movie";
  const movieData = {
    id: movieId,
    title: params.title || "Test Movie",
    director: params.director || "Test Director",
    plot: params.plot || "Test Plot",
    author: params.author || "Test user",
    authorId: params.authorId || "test-user",
    authorAvi: params.authorAvi || "Test Image",
    created: firebaseAdmin.firestore.Timestamp.fromDate(new Date()),
    endDate: firebaseAdmin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
  };

  const movieRef = firestore.collection("movieclubs").doc(MoviceClubId).collection("movies").doc(movieId);
  try {
    await movieRef.set(movieData);
    logVerbose("Movie data set");
  } catch (error) {
    logError("Error setting movie data:", error);
  };

  return movieData;
}

module.exports = { populateMovieData };