"use strict";

const assert = require("assert");
const { firebaseTest } = require("test/testHelper");
const { firestore } = require("firestore");
const { populateUserData, populateMovieClubData } = require("mocks");
const { movieClubs: { createMovieClub, updateMovieClub }, movies: { rotateMovieLogic } } = require("index");

describe("createMovieClub", () => {
  const wrapped = firebaseTest.wrap(createMovieClub);

  let user;
  let movieClubData;
  let movieClub;

  beforeEach(async () => {
    user = await populateUserData();

    movieClubData = {
      name: "Test Club",
      ownerId: user.id,
      ownerName: user.name,
      isPublic: true,
      timeInterval: "test",
      bannerUrl: "test",
    };
  });

  it("should create a new Movie Club", async () => {
    movieClub = await wrapped(movieClubData)
    const snap = await firestore.collection("movieclubs").doc(movieClub.id).get()
    const movieClubDoc = snap.data();

    assert(movieClubDoc.name == movieClubData.name);
    assert(movieClubDoc.ownerId == movieClubData.ownerId);
    assert(movieClubDoc.ownerName == movieClubData.ownerName);
    assert(movieClubDoc.isPublic == movieClubData.isPublic);
    assert(movieClubDoc.timeInterval == movieClubData.timeInterval);
    assert(movieClubDoc.bannerUrl == movieClubData.bannerUrl);
  });

  it("should error without required fields", async () => {
    try {
      await wrapped({})
      assert.fail('Expected error not thrown');
    } catch (error) {
      assert.match(error.message, /The function must be called with name, ownerId, ownerName, isPublic, timeInterval, bannerUrl./);
    };
  });
});

describe("updateMovieClub", () => {
  const wrapped = firebaseTest.wrap(updateMovieClub)

  let user;
  let movieClubData;
  let movieClub;

  beforeEach(async () => {
    user = await populateUserData();
    movieClub = await populateMovieClubData({ id: "1", ownerId: user.id, ownerName: user.name });
    
    movieClubData = {
      movieClubId: movieClub.id,
      name: "Updated Test Club",
      ownerId: user.id,
      ownerName: user.name,
      isPublic: false,
      timeInterval: "updated test interval",
      bannerUrl: "updated test banner URL",
    };
  });

  it("should update an existing Movie Club", async () => {
    await wrapped(movieClubData)
    const snap = await firestore.collection("movieclubs").doc(movieClub.id).get()
    const movieClubDoc = snap.data();

    assert(movieClubDoc.name == movieClubData.name);
    assert(movieClubDoc.ownerId == movieClubData.ownerId);
    assert(movieClubDoc.ownerName == movieClubData.ownerName);
    assert(movieClubDoc.isPublic == movieClubData.isPublic);
    assert(movieClubDoc.timeInterval == movieClubData.timeInterval);
    assert(movieClubDoc.bannerUrl == movieClubData.bannerUrl);
  });

  it("should error without required fields", async () => {
    try {
      await wrapped({})
      assert.fail('Expected error not thrown');
    } catch (error) {
      assert.match(error.message, /The function must be called with movieClubId, ownerId./);
    };
  });

  it("should not allow a user who does not own the movie club to update it", async () => {
    try {
      await wrapped({
        movieClubId: movieClub.id,
        name: "Updated Test Club",
        ownerId: "wrong-user-id",
      })
      assert.fail('Expected error not thrown');
    } catch (error) {
      assert.match(error.message, /ownerId does not match movieClub.ownerId/);
    };
  });
});
