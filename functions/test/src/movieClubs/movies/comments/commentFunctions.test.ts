const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { firestore } from "firestore";
import {
  populateUserData,
  populateMovieClubData,
  populateMovieData,
  populateCommentData,
} from "mocks";
import { comments } from "index";
import { UpdateUserData } from "src/users/userTypes";
import { UpdateMovieClubData } from "src/movieClubs/movieClubTypes";
import {
  DeleteCommentData,
  PostCommentData,
} from "src/movieClubs/movies/comments/commentTypes";
import { COMMENTS, MOVIE_CLUBS, MOVIES } from "src/utilities/collectionNames";
import { AuthData } from "firebase-functions/tasks";
import { populateMembershipData } from "test/mocks/membership";

// @ts-expect-error it works but ts won't detect it for some reason
// TODO: Figure out why ts can't detect the export on this
// prettier-ignore
const { deleteComment, postComment } = comments;

describe("Comment Functions", () => {
  const postWrapped = firebaseTest.wrap(postComment);
  const deleteWrapped = firebaseTest.wrap(deleteComment);

  let user: UpdateUserData;
  let auth: AuthData;
  let movieClub: UpdateMovieClubData;
  let movie: any;
  let text: string;

  beforeEach(async () => {
    const userMock = await populateUserData();
    user = userMock.user;
    auth = userMock.auth;

    movieClub = await populateMovieClubData({
      id: "1",
      ownerId: user.id,
      ownerName: user.name,
    });
    movie = await populateMovieData({ id: "1", movieClubId: movieClub.id });
    text = "This is a test comment";
    await populateMembershipData({
      userId: user.id,
      movieClubId: movieClub.id,
    });
  });

  describe("postComment", () => {
    let commentData: PostCommentData;

    beforeEach(async () => {
      commentData = {
        clubId: movieClub.id,
        movieId: movie.id,
        text: text,
        userId: user.id,
        userName: user.name,
        image: user.image,
        likes: 0,
        createdAt: new Date(),
      };
    });

    it("should create a new comment", async () => {
      await postWrapped({ data: commentData, auth: auth });

      const snap = await firestore
        .collection(MOVIE_CLUBS)
        .doc(movieClub.id)
        .collection(MOVIES)
        .doc(movie.id)
        .collection(COMMENTS)
        .where("userId", "==", user.id)
        .get();

      assert(snap.docs?.length == 1);

      const commentDoc = snap.docs[0].data();
      assert.equal(commentDoc.text, text);
      assert.equal(commentDoc.userId, user.id);
      assert.equal(commentDoc.username, user.name);
    });

    it("should error if the user isn't a member of the Movie Club", async () => {
      try {
        auth.uid = "wrong-user";
        await postWrapped({ data: commentData, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /You are not a member of this Movie Club./);
      }
    });

    it("should error without required fields", async () => {
      try {
        await postWrapped({ data: {}, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /The function must be called with movieClubId, movieId, text, username./,
        );
      }
    });

    it("should error without auth", async () => {
      try {
        await postWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);
      }
    });
  });

  describe("deleteComment", () => {
    let commentData: DeleteCommentData;

    beforeEach(async () => {
      commentData = {
        id: "",
        clubId: movieClub.id,
        movieId: movie.id,
      };

      const comment = await populateCommentData({
        movieClubId: movieClub.id,
        movieId: movie.id,
        userId: user.id,
        username: user.name,
      });

      commentData.id = comment.id;
    });

    it("should delete a comment", async () => {
      let snap;

      snap = await firestore
        .collection(MOVIE_CLUBS)
        .doc(movieClub.id)
        .collection(MOVIES)
        .doc(movie.id)
        .collection(COMMENTS)
        .doc(commentData.id)
        .get();

      assert.equal(snap.data()?.id, commentData.id);

      await deleteWrapped({ data: commentData, auth: auth });

      snap = await firestore
        .collection(MOVIE_CLUBS)
        .doc(movieClub.id)
        .collection(MOVIES)
        .doc(movie.id)
        .collection(COMMENTS)
        .doc(commentData.id)
        .get();

      assert.equal(snap.data(), undefined);
    });

    it("should error with wrong user", async () => {
      try {
        auth.uid = "wrong-uid";
        await deleteWrapped({ data: commentData, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /You cannot delete a comment that you don't own./,
        );

        const snap = await firestore
          .collection(MOVIE_CLUBS)
          .doc(movieClub.id)
          .collection(MOVIES)
          .doc(movie.id)
          .collection(COMMENTS)
          .doc(commentData.id)
          .get();

        assert.equal(snap.data()?.id, commentData.id);
      }
    });

    it("should error without required fields", async () => {
      try {
        await deleteWrapped({ data: {}, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /The function must be called with id, movieClubId, movieId/,
        );

        const snap = await firestore
          .collection(MOVIE_CLUBS)
          .doc(movieClub.id)
          .collection(MOVIES)
          .doc(movie.id)
          .collection(COMMENTS)
          .doc(commentData.id)
          .get();

        assert.equal(snap.data()?.id, commentData.id);
      }
    });

    it("should error without auth", async () => {
      try {
        await deleteWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);

        const snap = await firestore
          .collection(MOVIE_CLUBS)
          .doc(movieClub.id)
          .collection(MOVIES)
          .doc(movie.id)
          .collection(COMMENTS)
          .doc(commentData.id)
          .get();

        assert.equal(snap.data()?.id, commentData.id);
      }
    });
  });
});
