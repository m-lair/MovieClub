"use strict";

const assert = require("assert");
const { test } = require("test/testHelper");
const { db } = require("firestore");
const { populateUserData, populateMovieClubData, populateMovieData } = require("mocks");
const { comments: { deleteComment, postComment } } = require("index");

describe("comment functions", () => {
  const postWrapped = test.wrap(postComment);
  const deleteWrapped = test.wrap(deleteComment);

  let user, movieClub, movie;
  let text;
  let commentData;

  beforeEach(async () => {
    user = await populateUserData();
    movieClub = await populateMovieClubData({ id: "1", ownerId: user.id, ownerName: user.name });
    movie = await populateMovieData({ id: "1", movieClubId: movieClub.id });
    text = "This is a test comment";

    commentData = {
      movieClubId: movieClub.id,
      movieId: movie.id,
      text: text,
      userId: user.id,
      username: user.name,
    };
  });

  describe("postComment", () => {
    it("should create a new comment", async () => {
      await postWrapped(commentData);

      const snap = await db
        .collection("movieclubs")
        .doc(movieClub.id)
        .collection("movies")
        .doc(movie.id)
        .collection("comments")
        .where("userId", "==", user.id)
        .get();

      assert(snap.docs?.length == 1);

      const commentDoc = snap.docs[0].data();
      assert.strictEqual(commentDoc.text, text);
      assert.strictEqual(commentDoc.userId, user.id);
      assert.strictEqual(commentDoc.username, user.name);
    });

    it("should error without required fields", async () => {
      try {
        await postWrapped({});
        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /The function must be called with movieClubId, movieId, text, userId, username./);
      }
    });
  });

  describe("deleteComment", () => {
    it("should delete a comment", async () => {
      commentData.commentId = await postWrapped(commentData);
      await deleteWrapped(commentData);

      const snap = await db
        .collection("movieclubs")
        .doc(movieClub.id)
        .collection("movies")
        .doc(movie.id)
        .collection("comments")
        .doc(commentData.commentId)
        .get()

      assert.strictEqual(snap.data(), undefined);
    });

    it("should error without required fields", async () => {
      try {
        await deleteWrapped({});
        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /The function must be called with commentId, movieClubId, movieId/);
      }
    });
  });
});