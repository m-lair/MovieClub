const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { suggestions } from "index";
import { populateMovieClubData } from "mocks";
import { populateUserData, UserDataMock } from "test/mocks/user";
import { MovieClubMock } from "test/mocks/movieclub";
import { AuthData } from "firebase-functions/tasks";
import { CreateMovieClubSuggestionData } from "src/movieClubs/suggestions/suggestionTypes";
import { getMovieClubSuggestion, getMovieClubSuggestionDocRef } from "src/movieClubs/suggestions/suggestionHelpers";
import { populateMembershipData } from "test/mocks/membership";
import { populateSuggestionData } from "test/mocks/suggestion";

// @ts-expect-error it works but ts won't detect it for some reason
// TODO: Figure out why ts can't detect the export on this
// prettier-ignore
const { createMovieClubSuggestion, deleteMovieClubSuggestion } = suggestions;

describe.skip("Suggestion Functions", () => {
  let user: UserDataMock;
  let movieClub: MovieClubMock;
  let movieClubSuggestionData: CreateMovieClubSuggestionData;
  let auth: AuthData;

  beforeEach(async () => {
    const userMock = await populateUserData();
    user = userMock.user;
    auth = userMock.auth;

    movieClub = await populateMovieClubData({ ownerId: userMock.user.id });

    await populateMembershipData({
      userId: user.id,
      movieClubId: movieClub.id,
    });

    movieClubSuggestionData = {
      imdbId: "Test Imdb Id",
      userImage: "Test Image Url",
      userId: user.id,
      clubId: movieClub.id,
      userName: user.name
    }
  });

  describe("createMovieClubSuggestion", () => {
    const wrapped = firebaseTest.wrap(createMovieClubSuggestion);

    it("should create a new Movie Club Suggestion", async () => {
      await wrapped({ data: movieClubSuggestionData, auth: auth });
      const snap = await getMovieClubSuggestion(user.id, movieClub.id);
      const movieClubSuggestionbDoc = snap.data();
      
      assert.equal(movieClubSuggestionbDoc?.userImage, movieClubSuggestionData.userImage);
      assert.equal(movieClubSuggestionbDoc?.userName, movieClubSuggestionData.userName);
    });

    it("should error if user is not a member of the club", async () => {
      try {
        auth.uid = "wrong-uid";
        await wrapped({ data: movieClubSuggestionData, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /You are not a member of this Movie Club./,
        );
      }
    });

    it("should error without required fields", async () => {
      try {
        await wrapped({ data: {}, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /The function must be called with imageUrl, movieClubId, title./,
        );
      }
    });

    it("should error without auth", async () => {
      try {
        await wrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);
      }
    });
  });

  describe("deleteUserMovieClubSuggestion", () => {
    const wrapped = firebaseTest.wrap(deleteMovieClubSuggestion);

    beforeEach(async () => {
      await populateSuggestionData({ userId: user.id, movieClubId: movieClub.id })
    });

    it("should delete a suggestion for the requesting user", async () => {
      const snap = await getMovieClubSuggestionDocRef(user.id, movieClub.id).get();
      const movieClubSuggestionDoc = snap.data();

      assert.equal(movieClubSuggestionDoc?.imageUrl, movieClubSuggestionData.userImage);
      await wrapped({ data: movieClubSuggestionData, auth: auth });

      const deletedSnap = await getMovieClubSuggestionDocRef(user.id, movieClub.id).get();
      const deletedMovieClubSuggestionDoc = deletedSnap.data();

      assert.equal(deletedMovieClubSuggestionDoc, undefined)
    });

    it("should error without required fields", async () => {
      try {
        await wrapped({ data: {}, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The function must be called with movieClubId./);
      }
    });

    it("should error without auth", async () => {
      try {
        await wrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);
      }
    });
  });
});