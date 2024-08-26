const test = require('firebase-functions-test')({
    databaseURL: 'https://movieclub-93714.firebaseio.com',
    storageBucket: 'movieclub-93714.appspot.com',
    projectId: 'movieclub-93714',
  }, '/Users/marcus/Library/Mobile Documents/com~apple~CloudDocs/Documents/movieclub-93714-f6efcc256851.json');

const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const functions = require('../index');

describe('rotateMovie', () => {
  it('should rotate the movie every 24 hours', async () => {
    // Set up test data
    const movieClubRef = db.collection('movieclubs').doc('test-club');
    const membershipRef = movieClubRef.collection('memberships').doc('test-membership');
    const movieRef = membershipRef.collection('queue').doc('test-movie');

    await movieRef.set({ title: 'Test Movie' });
    await membershipRef.set({ queue: [movieRef.id] });
    await movieClubRef.set({});

    // Call the rotateMovie function
    const context = { req: {}, res: {} };
    await functions.rotateMovie(context);

    // Verify that the movie has been rotated
    const newMovieRef = await movieClubRef.collection('movies').get();
    expect(newMovieRef.docs.length).toBe(1);
    const newMovieData = newMovieRef.docs[0].data();
    expect(newMovieData.title).toBe('Test Movie');
    expect(newMovieData.director).toBeDefined();
    expect(newMovieData.plot).toBeDefined();
  });
});