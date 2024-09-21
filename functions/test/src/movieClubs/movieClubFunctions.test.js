'use strict';

const assert = require('assert');
const { test } = require("test/testHelper")
const { db } = require('firestore');
const populate = require('mocks/PopulateTestData');
const { movies: { rotateMovieLogic } } = require('index');

test.mockConfig({ omdbapi: { key: 'ab92d369' }});

describe('rotateMovie', () => {
  it('should rotate the movie every 24 hours', async () => {
    try {
      await populate.populateDefaultData(2);
    } catch (error) {
      console.log(error);
    }

    const movieClubRef = await db.collection('movieclubs').get();
    // Call the wrapped rotateMovie function
    console.log('Calling rotateMovie function...');
    await rotateMovieLogic();
    console.log('Finished running rotateMovie function');
    for (let club of movieClubRef.docs) {
      console.log(club.id);
      assert(db.collection("movieclubs").doc(club.id).collection('movies') !== null);
      assert(db.collection("movieclubs").doc(club.id).collection('movies') !== undefined);
      assert((await db.collection("movieclubs").doc(club.id).collection('movies').get()).docs.length >= 2);
    }

  });

  after(() => {
    test.cleanup();
    console.log('Test cleanup complete');
    console.log('Test complete');
  });
});