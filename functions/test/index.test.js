'use strict';
const test = require('firebase-functions-test')({
  databaseURL: 'localhost:8080',
  projectId: 'movieclub-93714',
}, '/Users/marcus/Library/Mobile Documents/com~apple~CloudDocs/Documents/movieclub-93714-f6efcc256851.json');
const admin = require('firebase-admin');
const { rotateMovieLogic } = require('../index');
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
db.settings({ host: 'localhost:8080', ssl: false });
//test.mockConfig({ omdbapi: { key: 'ab92d369' }});

describe('rotateMovie', () => {
  it('should rotate the movie every 24 hours', async () => {
    console.log('Test Movie Club Data');
    const movieClubRef = db.collection('movieclubs').doc('test-club');
    const movieClubData = {
      name: 'Test Club',
      description: 'Test Description',
      image: 'Test Image',
      created: admin.firestore.Timestamp.fromDate(new Date()),
      movieEndDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)),
    };

    try {
    await movieClubRef.set(movieClubData);
    console.log('movie club data set');
    } catch (error) {
      throw new Error(`Error setting movie club data: ${error}`);
    }
    // User Test Data
    const userRef = db.collection('users').doc('test-user');
    const userData = {
      name: 'Test User',
      id: 'test-user',
      image: 'Test Image',
      bio: 'Test Bio'
    };

    try {
    await userRef.set(userData);
    console.log('user data set');
    } catch (error) {
      throw new Error(`Error setting user data: ${error}`);
    }
    // Membership Test Data
    const membershipRef = userRef.collection('memberships').doc("test-club");
    const membershipData = {
      clubID: movieClubData.name,
      clubName: movieClubData.name,
      queue: [{
        title: 'Test Movie',
        author: 'Test user',
        authorID: 'test-user',
        authorAvi: 'Test Avi',
      }]
    };

    try {
    await membershipRef.set(membershipData);
    console.log('membership data set');
    } catch (error) {
      throw new Error(`Error setting membership data: ${error}`);
    }

    // Movie Test Data
    const movieRef = movieClubRef.collection('movies').doc('test-movie');
    const movieData = {
      title: 'Test Movie',
      director: 'Test Director',
      plot: 'Test Plot',
    };

    try{
    await movieRef.set(movieData);
    console.log('movie data set');
    } catch (error) {
      throw new Error(`Error setting movie data: ${error}`);
    }

    const memberRef = movieClubRef.collection('members').doc('test-user');
    const memberData = {
      name: 'Test User',
      id: 'test-user',
      avi: 'Test Image',
      dateAdded: admin.firestore.Timestamp.fromDate(new Date())
    };

    try {
    await memberRef.set(memberData);
    console.log('member data set');
    } catch (error) {
      throw new Error(`Error setting member data: ${error}`);
    }

    // Call the wrapped rotateMovie function
    console.log('Calling rotateMovie function...');
    await rotateMovieLogic();

    console.log('Finished running rotateMovie function');

  });
    after(() => {
      console.log('Test complete');
    });
  });