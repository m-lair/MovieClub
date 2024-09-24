const { logError, logVerbose } = require("utilities");
const { db } = require("firestore");

async function populateMemberData(params = {}) {
  logVerbose('Populating member data...');
  const movieClubId = params.movieClubId || "test-club-id"
  const name = params.name || 'Test user'
  const id = params.id || 'test-user-id'

  const memberData = {
    name: name,
    id: id,
    dateAdded: admin.firestore.Timestamp.fromDate(new Date()),
  }

  const membersRef = db.collection("movieclubs").doc(movieClubId).collection('members').doc(id)
  try {
    await membersRef.set(memberData);
    logVerbose('Member data set');
  } catch (error) {
    logError("Error setting member data:", error);
  }
}

module.exports = { populateMemberData };