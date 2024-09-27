const { logError, logVerbose } = require("helpers");
const { firestore, firebaseAdmin } = require("firestore");

async function populateMovieClubData(params = {}) {
  logVerbose("Populating movie club data...");
  const testMoviceClubId = params.id || "Test Club";
  const movieClubData = {
    id: testMoviceClubId,
    name: params.name || "Test Club",
    description: params.description || "Test Description",
    image: params.image || "Test Image",
    ownerId: params.ownerId || "test-user-id",
    ownerName: params.ownerName || "Test User",
    created: firebaseAdmin.firestore.Timestamp.fromDate(new Date()),
    movieEndDate: firebaseAdmin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)),
  };

  const movieClubRef = firestore.collection("movieclubs").doc(testMoviceClubId);
  try {
    await movieClubRef.set(movieClubData);
    logVerbose("Movie club data set");
  } catch (error) {
    logError("Error setting movie club data:", error);
  };

  return movieClubData;
}

module.exports = { populateMovieClubData };