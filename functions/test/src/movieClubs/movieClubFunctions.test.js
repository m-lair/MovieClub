"use strict";

const assert = require("assert");
const { test } = require("test/testHelper")
const { db } = require("firestore");
const { populateUserData } = require("mocks")
const { movieClubs: { createMovieClub }, movies: { rotateMovieLogic } } = require("index");

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
