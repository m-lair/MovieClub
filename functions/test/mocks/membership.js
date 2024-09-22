const { logError, logVerbose } = require("utilities");
const { db } = require("firestore");

async function populateMembershipData(params = {}) {
  logVerbose('Populating membership data...');
  const userId = params.userId || 'test-user';
  const movieClubId = params.movieClubId || 'test-club';
  const membershipData = {
    clubID: params.clubID || 'test-club',
    clubName: params.clubName || 'Test Club',
    queue: [{
      title: 'The Matrix',
      author: 'Test user',
      authorID: 'Test user',
      authorAvi: 'Test Image',
      created: admin.firestore.Timestamp.fromDate(new Date()),
      endDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
    }]
  };

  const membershipRef = db.collection('users').doc(userId).collection('memberships').doc(movieClubId);
  try {
    await membershipRef.set(membershipData);
    logVerbose('Membership data set');
  } catch (error) {
    logError("Error setting membership data:", error);
  }
};

module.exports = { populateMembershipData };