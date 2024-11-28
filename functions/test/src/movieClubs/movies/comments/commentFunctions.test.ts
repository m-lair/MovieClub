const assert = require("assert");
import { firebaseTest } from "test/testHelper";
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
  LikeCommentData,
  PostCommentData,
  UnlikeCommentData,
} from "src/movieClubs/movies/comments/commentTypes";
import { AuthData } from "firebase-functions/tasks";
import { populateMembershipData } from "test/mocks/membership";
import { getCommentsDocRef, getCommentsRef } from "src/movieClubs/movies/comments/commentHelpers";

// @ts-expect-error it works but ts won't detect it for some reason
// TODO: Figure out why ts can't detect the export on this
// prettier-ignore
const { deleteComment, postComment, likeComment, unlikeComment } = comments;

describe("Comment Functions", () => {
  const postWrapped = firebaseTest.wrap(postComment);
  const deleteWrapped = firebaseTest.wrap(deleteComment);
  const likeWrapped = firebaseTest.wrap(likeComment);
  const unlikeWrapped = firebaseTest.wrap(unlikeComment);

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
        likedBy: [],
        createdAt: new Date(),
        replyToId: "",
      };
    });

    it("should create a new comment", async () => {
      await postWrapped({ data: commentData, auth: auth });

      const commentsRef = getCommentsRef(movieClub.id, movie.id)
      const snap = await commentsRef.where("userId", "==", user.id).get();

      assert(snap.docs?.length == 1);

      const commentDoc = snap.docs[0].data();

      assert.equal(commentDoc.text, text);
      assert.equal(commentDoc.userId, user.id);
      assert.equal(commentDoc.userName, user.name);
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
          /The function must be called with clubId, movieId, text, userName./,
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

      snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.id).get();

      assert.equal(snap.data()?.id, commentData.id);

      await deleteWrapped({ data: commentData, auth: auth });

      snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.id).get();

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

        const snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.id).get();

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
          /The function must be called with id, clubId, movieId/,
        );

        const snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.id).get();

        assert.equal(snap.data()?.id, commentData.id);
      }
    });

    it("should error without auth", async () => {
      try {
        await deleteWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);

        const snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.id).get();

        assert.equal(snap.data()?.id, commentData.id);
      }
    });
  });

  describe("likeComment", () => {
    let commentData: LikeCommentData;

    beforeEach(async () => {
      commentData = {
        commentId: "",
        clubId: movieClub.id,
        movieId: movie.id,
      };

      const comment = await populateCommentData({
        movieClubId: movieClub.id,
        movieId: movie.id,
        userId: user.id,
        username: user.name,
      });

      commentData.commentId = comment.id;
    });

    it("should increment the likes", async () => {
      await likeWrapped({ data: commentData, auth: auth })
      const snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.commentId).get();

      assert.equal(snap.data()?.likes, 1);
    });

    it("should add user to the likedBy array", async () => {
      await likeWrapped({ data: commentData, auth: auth })

      const snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.commentId).get();

      assert.deepEqual(snap.data()?.likedBy, [user.id]);
    });

    it("should error without required fields", async () => {
      try {
        await likeWrapped({ data: {}, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /The function must be called with clubId, movieId, commentId./,
        );
      }
    });

    it("should error without auth", async () => {
      try {
        await likeWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);
      }
    });
  });

  describe("unlikeComment", () => {
    let commentData: UnlikeCommentData;

    beforeEach(async () => {
      commentData = {
        commentId: "",
        clubId: movieClub.id,
        movieId: movie.id,
      };

      const comment = await populateCommentData({
        movieClubId: movieClub.id,
        movieId: movie.id,
        userId: user.id,
        username: user.name,
        likes: 1,
        likedBy: [user.id]
      });

      commentData.commentId = comment.id;
    });

    it("should decerement the likes", async () => {
      await unlikeWrapped({ data: commentData, auth: auth })
      const snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.commentId).get();

      assert.equal(snap.data()?.likes, 0);
    });

    it("should remove user from the likedBy array", async () => {
      await unlikeWrapped({ data: commentData, auth: auth })

      const snap = await getCommentsDocRef(movieClub.id, movie.id, commentData.commentId).get();

      assert.deepEqual(snap.data()?.likedBy, []);
    });

    it("should error without required fields", async () => {
      try {
        await unlikeWrapped({ data: {}, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /The function must be called with clubId, movieId, commentId./,
        );
      }
    });

    it("should error without auth", async () => {
      try {
        await unlikeWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);
      }
    });
  });
});
