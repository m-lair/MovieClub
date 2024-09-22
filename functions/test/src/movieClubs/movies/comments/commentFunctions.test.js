"use strict";

const assert = require("assert");
const { test } = require("test/testHelper");
const { db } = require("firestore");
const { populateUserData, populateMovieClubData, populateMovieData } = require("mocks");
const { comments: { postComment } } = require("index");

describe("postComment", () => {
  const wrapped = test.wrap(postComment)

  let user, movieClub, movie;
  let text;
  let commentData;

  beforeEach(async () => {
    user = await populateUserData();
    movieClub = await populateMovieClubData({ id: "1", ownerID: user.uid, ownerName: user.name });
    movie = await populateMovieData({ id: "1", movieClubId: movieClub.id });

    text = "This is a test comment";

    commentData = {
      movieClubId: movieClub.id,
      movieId: movie.id,
      text: text,
      userID: user.uid,
      username: user.name,
    };

    await wrapped(commentData);
  });

  after(() => {
    test.cleanup();
  });

  it("should create a new comment", async () => {
    const snap = await db
      .collection("movieclubs")
      .doc(movieClub.id)
      .collection("movies")
      .doc(movie.id)
      .collection("comments")
      .where("userID", "==", user.uid)
      .get();

    assert(snap.docs?.length > 0);

    const commentDoc = snap.docs[0].data();

    assert(commentDoc.text == text);
    assert(commentDoc.userID == user.uid);
    assert(commentDoc.username == user.name);
  });

  it("should error without required fields", async () => {
    try {
      await wrapped({})
      assert.fail("Expected error not thrown");
    } catch (error) {
      assert.match(error.message, /The function must be called with movieClubId, movieId, text, userID, username./);
    };
  });
});