const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { firestore } from "firestore";
import { populateUserData, populateMovieClubData, populateMovieData, populateCommentData } from "mocks";
import { comments } from "index";
import { UpdateUserData } from "src/users/userTypes";
import { UpdateMovieClubData } from "src/movieClubs/movieClubTypes";
import { DeleteCommentData, PostCommentData } from "src/movieClubs/movies/comments/commentTypes";

// @ts-ignore
// TODO: Figure out why ts can't detect the export on this
const { deleteComment, postComment } = comments

describe("Comment Functions", () => {
  const postWrapped = firebaseTest.wrap(postComment);
  const deleteWrapped = firebaseTest.wrap(deleteComment);

  let user: UpdateUserData;
  let movieClub: UpdateMovieClubData;
  let movie: any;
  let text: string;

  beforeEach(async () => {
    user = await populateUserData();
    movieClub = await populateMovieClubData({ id: "1", ownerId: user.id, ownerName: user.name });
    movie = await populateMovieData({ id: "1", movieClubId: movieClub.id });
    text = "This is a test comment";
  });

  describe("postComment", () => {
    let commentData: PostCommentData;

    beforeEach(async () => {
      commentData = {
        movieClubId: movieClub.id,
        movieId: movie.id,
        text: text,
        userId: user.id,
        username: user.name,
      };
    });

    it("should create a new comment", async () => {
      await postWrapped({ data: commentData });

      const snap = await firestore
        .collection("movieclubs")
        .doc(movieClub.id)
        .collection("movies")
        .doc(movie.id)
        .collection("comments")
        .where("userId", "==", user.id)
        .get();

      assert(snap.docs?.length == 1);

      const commentDoc = snap.docs[0].data();
      assert.equal(commentDoc.text, text);
      assert.equal(commentDoc.userId, user.id);
      assert.equal(commentDoc.username, user.name);
    });

    it("should error without required fields", async () => {
      try {
        await postWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The function must be called with movieClubId, movieId, text, userId, username./);
      }
    });
  });

  describe("deleteComment", () => {
    let commentData: DeleteCommentData;

    beforeEach(async () => {
      commentData = {
        id: "",
        movieClubId: movieClub.id,
        movieId: movie.id,
      };

      const comment = await populateCommentData({ movieClubId: movieClub.id, movieId: movie.id, userId: user.id, username: user.name });

      commentData.id = comment.id;
    });

    it("should delete a comment", async () => {
      let snap;

      snap = await firestore
        .collection("movieclubs")
        .doc(movieClub.id)
        .collection("movies")
        .doc(movie.id)
        .collection("comments")
        .doc(commentData.id)
        .get()

      assert.equal(snap.data()?.id, commentData.id);

      await deleteWrapped({ data: commentData });

      snap = await firestore
        .collection("movieclubs")
        .doc(movieClub.id)
        .collection("movies")
        .doc(movie.id)
        .collection("comments")
        .doc(commentData.id)
        .get()

      assert.equal(snap.data(), undefined);
    });

    it("should error without required fields", async () => {
      try {
        await deleteWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The function must be called with id, movieClubId, movieId/);

        const snap = await firestore
          .collection("movieclubs")
          .doc(movieClub.id)
          .collection("movies")
          .doc(movie.id)
          .collection("comments")
          .doc(commentData.id)
          .get()

        assert.equal(snap.data()?.id, commentData.id)
      }
    });
  });
});