const { firestore, firebaseAdmin } = require("firestore");
const { logError, logVerbose } = require("utilities");

async function populateCommentData(params = {}) {
  logVerbose('Populating comment data...');
  const movieClubId = params.movieClubId || "test-club-id";
  const movieId = params.movieId || "test-movie-id";
  const name = params.name || 'Test user';
  const id = params.id || 'test-comment-id';

  const commentData = {
    id: id,
    image: params.image || "Test image",
    text: params.text || "Test text",
    userId: params.username || "test-user-id",
    username: params.username || "Test User",
    likes: params.likes || 0,
    date: firebaseAdmin.firestore.Timestamp.fromDate(new Date()),
  };

  const commentsRef = firestore.collection("movieclubs").doc(movieClubId).collection('movies').doc(movieId).collection('comments').doc(id)
  try {
    await commentsRef.set(commentData);
    logVerbose('comment data set');
  } catch (error) {
    logError("Error setting comment data:", error);
  }
};

module.exports = { populateCommentData };