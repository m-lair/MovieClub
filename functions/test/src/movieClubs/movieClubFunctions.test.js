"use strict";

const assert = require("assert");
const { test } = require("test/testHelper")
const { db } = require("firestore");
const { populateUserData, populateMovieClubData } = require("mocks")
const { movieClubs: { createMovieClub, updateMovieClub }, movies: { rotateMovieLogic } } = require("index");

describe("createMovie", () => {
  const wrapped = test.wrap(createMovieClub)

  let user;
  let movieClubData;
  let movieClub;

  beforeEach(async () => {
    user = await populateUserData();

    movieClubData = {
      name: "Test Club",
      ownerID: user.id,
      ownerName: user.name,
      isPublic: true,
      timeInterval: "test",
      bannerUrl: "test",
    };
  });

  after(() => {
    test.cleanup();
  });

  it("should create a new Movie Club", async () => {
    movieClub = await wrapped(movieClubData)
    const snap = await db.collection("movieclubs").doc(movieClub.id).get()
    const movieClubDoc = snap.data();

    assert(movieClubDoc.name == movieClubData.name);
    assert(movieClubDoc.ownerID == movieClubData.ownerID);
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
      assert.match(error.message, /The function must be called with name, ownerID, ownerName, isPublic, timeInterval, bannerUrl./);
    };
  });
});

describe("updateMovieClub", () => {
  const wrapped = test.wrap(updateMovieClub)

  let user;
  let movieClubData;
  let movieClub;

  beforeEach(async () => {
    user = await populateUserData();
    movieClub = await populateMovieClubData({ id: "1", ownerID: user.id, ownerName: user.name });
    
    movieClubData = {
      movieClubId: movieClub.id,
      name: "Updated Test Club",
      ownerID: user.id,
      ownerName: user.name,
      isPublic: false,
      timeInterval: "updated test interval",
      bannerUrl: "updated test banner URL",
    };
  });

  after(() => {
    test.cleanup();
  });

  it("should update an existing Movie Club", async () => {
    await wrapped(movieClubData)
    const snap = await db.collection("movieclubs").doc(movieClub.id).get()
    const movieClubDoc = snap.data();

    assert(movieClubDoc.name == movieClubData.name);
    assert(movieClubDoc.ownerID == movieClubData.ownerID);
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
      assert.match(error.message, /The function must be called with movieClubId, ownerID./);
    };
  });

  it("should not allow a user who does not own the movie club to update it", async () => {
    try {
      await wrapped({
        movieClubId: movieClub.id,
        name: "Updated Test Club",
        ownerID: "wrong-user-id",
      })
      assert.fail('Expected error not thrown');
    } catch (error) {
      assert.match(error.message, /ownerID does not match movieClub.ownerID/);
    };
  });
});
