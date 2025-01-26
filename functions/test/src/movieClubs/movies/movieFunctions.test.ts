const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { movies } from "index";
import { UpdateMovieClubData } from "src/movieClubs/movieClubTypes";
import { populateMovieClubData, populateMovieData } from "mocks";
import { populateUserData } from "test/mocks/user";
import { AuthData } from "firebase-functions/tasks";
import { getMovieDocRef } from "src/movieClubs/movies/movieHelpers";
import { LikeMovieData } from "src/movieClubs/movies/movieTypes";
import { UpdateUserData } from "src/users/userTypes";
import { populateMembershipData } from "test/mocks/membership";
import { MovieMock } from "test/mocks/movie";

// @ts-expect-error it works but ts won't detect it for some reason
// TODO: Figure out why ts can't detect the export on this
// prettier-ignore
const { likeMovie, dislikeMovie } = movies;

describe("Movie Functions", () => {
  const likeWrapped = firebaseTest.wrap(likeMovie);
  const dislikeWrapped = firebaseTest.wrap(likeMovie);

  describe("likeMovie", () => {

    let auth: AuthData;
    let movieClub: UpdateMovieClubData;
    let movie: MovieMock;
    let user: UpdateUserData;
    let likeMovieData: LikeMovieData;

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

      await populateMembershipData({
        userId: user.id,
        movieClubId: movieClub.id,
      });

      likeMovieData = {
        movieClubId: movieClub.id,
        movieId: movie.id,
        name: user.name
      }
    })

    it("adds the user's name to likedBy", async () => {
      const movieDocSnap = await getMovieDocRef(movie.id, movieClub.id).get()
      const movieDoc = movieDocSnap.data();

      assert.deepEqual(movieDoc?.likedBy, [])

      await likeWrapped({ data: likeMovieData, auth: auth });

      const updatedMovieDocSnap = await getMovieDocRef(movie.id, movieClub.id).get()
      const updatedMovieDoc = updatedMovieDocSnap.data();

      assert.deepEqual(updatedMovieDoc?.likedBy, [user.name])
    })

    it("removes the user's name from dislikedBy", async () => {
      await dislikeWrapped({ data: likeMovieData, auth: auth });
      const movieDocSnap = await getMovieDocRef(movie.id, movieClub.id).get()
      const movieDoc = movieDocSnap.data();

      assert.deepEqual(movieDoc?.dislikedBy, [user.name])

      await likeWrapped({ data: likeMovieData, auth: auth });

      const updatedMovieDocSnap = await getMovieDocRef(movie.id, movieClub.id).get()
      const updatedMovieDoc = updatedMovieDocSnap.data();

      assert.deepEqual(updatedMovieDoc?.dislikedBy, [])
    })

    it("removes the user's name from likedBy with undo", async () => {
      await likeWrapped({ data: likeMovieData, auth: auth });
      const movieDocSnap = await getMovieDocRef(movie.id, movieClub.id).get()
      const movieDoc = movieDocSnap.data();

      assert.deepEqual(movieDoc?.likedBy, [user.name])

      likeMovieData.undo = true

      await likeWrapped({ data: likeMovieData, auth: auth });

      const updatedMovieDocSnap = await getMovieDocRef(movie.id, movieClub.id).get()
      const updatedMovieDoc = updatedMovieDocSnap.data();

      assert.deepEqual(updatedMovieDoc?.likedBy, [])
    })
  })

  describe("dislikeMovie", () => {

  })
 }
)