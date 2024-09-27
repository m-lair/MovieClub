const { logError, logVerbose } = require("utilities");
const { firestore } = require("firestore");

async function populateMembershipData(params = {}) {
  logVerbose('Populating membership data...');
  const userId = params.userId || 'test-user';
  const movieClubId = params.movieClubId || 'test-club';
  const membershipData = {
    clubId: params.clubId || 'test-club',
    clubName: params.clubName || 'Test Club',
    queue: [{
      title: 'The Matrix',
      author: 'Test user',
      authorId: 'Test user',
      authorAvi: 'Test Image',
      created: firestore.Timestamp.fromDate(new Date()),
      endDate: firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
    }]
  };

  const membershipRef = firestore.collection('users').doc(userId).collection('memberships').doc(movieClubId);
  try {
    await membershipRef.set(membershipData);
    logVerbose('Membership data set');
  } catch (error) {
    logError("Error setting membership data:", error);
  }
};

module.exports = { populateMembershipData };