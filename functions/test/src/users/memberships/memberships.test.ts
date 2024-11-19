const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { memberships } from "index";
import { populateUserData, UserDataMock } from "test/mocks/user";
import { AuthData } from "firebase-functions/tasks";
import { populateMemberData, populateMovieClubData } from "mocks";
import { JoinMovieClubData, LeaveMovieClubData } from "src/users/memberships/membershipTypes";
import { MovieClubMock } from "test/mocks/movieclub";
import { getUserMembership } from "src/users/memberships/membershipHelpers";
import { getMovieClubMember } from "src/movieClubs/movieClubHelpers";
import { populateMembershipData } from "test/mocks/membership";
import { getMovieClubSuggestion } from "src/movieClubs/suggestions/suggestionHelpers";
import { populateSuggestionData } from "test/mocks/suggestion";

// @ts-expect-error it works but ts won't detect it for some reason
// TODO: Figure out why ts can't detect the export on this
// prettier-ignore
const { joinMovieClub, leaveMovieClub } = memberships;

describe("membershipFunctions", () => {
  let user: UserDataMock;
  let movieClub: MovieClubMock;
  let auth: AuthData;

  beforeEach(async () => {
    const { user: userMock, auth: authMock } = await populateUserData();
    user = userMock;
    auth = authMock;

    movieClub = await populateMovieClubData();
  });

  describe("joinMovieClub", () => {
    let membershipData: JoinMovieClubData;
    const joinMovieClubWrapped = firebaseTest.wrap(joinMovieClub);

    beforeEach(async () => {
      membershipData = {
        image: "Test Image",
        clubId: movieClub.id,
        clubName: movieClub.name,
        userName: user.name,
      };
    });

    it("should create a User Membership collection", async () => {
      await joinMovieClubWrapped({ data: membershipData, auth: auth });

      const userMembershipSnap = await getUserMembership(user.id, movieClub.id)
      const userMembership = userMembershipSnap.data();

      assert.equal(userMembershipSnap.id, movieClub.id);
      assert.equal(userMembership?.movieClubName, movieClub.name);
      assert(userMembership?.createdAt);
    });

    it("should create a Movie Club Member collection", async () => {
      await joinMovieClubWrapped({ data: membershipData, auth: auth });

      const movieClubMemberSnap = await getMovieClubMember(user.id, movieClub.id)
      const movieClubMember = movieClubMemberSnap.data();

      assert.equal(movieClubMemberSnap.id, user.id);
      assert.equal(movieClubMember?.image, membershipData.image);
      assert.equal(movieClubMember?.username, user.name);
      assert(movieClubMember?.createdAt);
    });

    it("should error if movie club is not public", async () => {
      try {
        movieClub = await populateMovieClubData({ isPublic: false });
        membershipData.clubId = movieClub.id;

        await joinMovieClubWrapped({ data: membershipData, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The Movie Club is not publicly joinable./);
      }
    });

    it("should error without required fields", async () => {
      try {
        await joinMovieClubWrapped({ data: {}, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /The function must be called with image, movieClubId, movieClubName, username./,
        );
      }
    });

    it("should error without auth", async () => {
      try {
        await joinMovieClubWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);
      }
    });
  });

  describe("leaveMovieClub", () => {
    let membershipData: LeaveMovieClubData;
    const leaveMovieClubWrapped = firebaseTest.wrap(leaveMovieClub);

    beforeEach(async () => {
      membershipData = { clubId: movieClub.id };

      await populateMembershipData({ userId: user.id, movieClubId: movieClub.id, movieClubName: movieClub.name });
      await populateMemberData({ userId: user.id, username: user.name, movieClubId: movieClub.id });
      await populateSuggestionData({ userId: user.id, username: user.name, movieClubId: movieClub.id });
    });

    it("should remove a users membership", async () => {
      const userMembershipSnapBefore = await getUserMembership(user.id, movieClub.id);
      const { movieClubName } = userMembershipSnapBefore.data()!;
      assert.equal(movieClubName, movieClub.name);

      await leaveMovieClubWrapped({ data: membershipData, auth: auth });

      const userMembershipSnap = await getUserMembership(user.id, movieClub.id);

      assert.equal(userMembershipSnap.data(), undefined);
    });

    it("should remove the movie club member", async () => {
      const movieClubMemberSnapBefore = await getMovieClubMember(user.id, movieClub.id);

      const { image, username } = movieClubMemberSnapBefore.data()!;
      assert.equal(image, "Test Image");
      assert.equal(username, user.name);

      await leaveMovieClubWrapped({ data: membershipData, auth: auth });

      const movieClubMemberSnap = await getMovieClubMember(user.id, movieClub.id);

      assert.equal(movieClubMemberSnap.data(), undefined);
    });

    it("should delete movie club suggestion for user", async () => {
      const movieClubSuggestionSnapBefore = await getMovieClubSuggestion(user.id, movieClub.id);

      const { imageUrl, username } = movieClubSuggestionSnapBefore.data()!;
      assert.equal(imageUrl, "Test Image Url");
      assert.equal(username, user.name);

      await leaveMovieClubWrapped({ data: membershipData, auth: auth });

      const movieClubSuggestionSnap = await getMovieClubSuggestion(user.id, movieClub.id);

      assert.equal(movieClubSuggestionSnap.data(), undefined);
    });

    it("should error without required fields", async () => {
      try {
        await leaveMovieClubWrapped({ data: {}, auth: auth });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(
          error.message,
          /The function must be called with movieClubId./,
        );
      }
    });

    it("should error without auth", async () => {
      try {
        await leaveMovieClubWrapped({ data: {} });
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);
      }
    });
  });
});