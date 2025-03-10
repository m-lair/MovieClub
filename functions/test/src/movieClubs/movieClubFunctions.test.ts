const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { movieClubs } from "index";
import { populateMovieClubData } from "mocks";
import { populateUserData, UserDataMock } from "test/mocks/user";
import { MovieClubMock } from "test/mocks/movieclub";
import { AuthData } from "firebase-functions/tasks";
import { getMovieClub } from "src/movieClubs/movieClubHelpers";

import {
  MovieClubData,
  UpdateMovieClubData,
} from "src/movieClubs/movieClubTypes";

// @ts-expect-error it works but ts won't detect it for some reason
// TODO: Figure out why ts can't detect the export on this
// prettier-ignore
const { createMovieClub, updateMovieClub } = movieClubs;

describe("createMovieClub", () => {
  const wrapped = firebaseTest.wrap(createMovieClub);

  let user: UserDataMock;
  let movieClubData: MovieClubData;
  let auth: AuthData;

  beforeEach(async () => {
    const userMock = await populateUserData();
    user = userMock.user;
    auth = userMock.auth;

    const userId = user.id || "test-user-id";
    const username = user.name || "test-user-name";

    movieClubData = {
      bannerUrl: "Test Banner Url",
      description: "Test Description",
      isPublic: true,
      name: "Test Club",
      numMembers: 1,
      ownerId: userId,
      ownerName: username,
      timeInterval: 0,
    };
  });

  it("should create a new Movie Club", async () => {
    const movieClubId = await wrapped({ data: movieClubData, auth: auth });
    const snap = await getMovieClub(movieClubId);

    const movieClubDoc = snap.data();

    assert.equal(movieClubDoc?.bannerUrl, movieClubData.bannerUrl);
    assert.equal(movieClubDoc?.description, movieClubData.description);
    assert.equal(movieClubDoc?.isPublic, movieClubData.isPublic);
    assert.equal(movieClubDoc?.name, movieClubData.name);
    assert.equal(movieClubDoc?.numMembers, movieClubData.numMembers);
    assert.equal(movieClubDoc?.ownerId, movieClubData.ownerId);
    assert.equal(movieClubDoc?.ownerName, movieClubData.ownerName);
    assert.equal(movieClubDoc?.timeInterval, movieClubData.timeInterval);
  });

  it("should error without required fields", async () => {
    try {
      await wrapped({ data: {}, auth: auth });
      assert.fail("Expected error not thrown");
    } catch (error: any) {
      assert.match(
        error.message,
        /The function must be called with isPublic, name, ownerName, timeInterval./,
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

describe("updateMovieClub", () => {
  const wrapped = firebaseTest.wrap(updateMovieClub);

  let user: UserDataMock;
  let movieClubData: UpdateMovieClubData;
  let movieClub: MovieClubMock;
  let auth: AuthData;

  beforeEach(async () => {
    const userMock = await populateUserData();
    user = userMock.user;
    auth = userMock.auth;

    movieClub = await populateMovieClubData({
      id: "1",
      ownerId: user.id,
      ownerName: user.name,
    });

    movieClubData = {
      id: movieClub.id,
      description: "Updated Description",
      isPublic: false,
      image: "Updated Image",
      name: "Updated Test Club",
      numMembers: 2,
      ownerId: "Not Updated ownerId",
      ownerName: "Not Updated ownerName",
      timeInterval: 0,
      bannerUrl: "Updated test banner URL",
    };
  });

  it("should update an existing Movie Club", async () => {
    await wrapped({ data: movieClubData, auth: auth });
    const snap = await getMovieClub(movieClub.id);
    const movieClubDoc = snap.data();

    assert.equal(movieClubDoc?.bannerUrl, movieClubData.bannerUrl);
    assert.equal(movieClubDoc?.description, movieClubData.description);
    assert.equal(movieClubDoc?.image, movieClubData.image);
    assert.equal(movieClubDoc?.isPublic, movieClubData.isPublic);
    assert.equal(movieClubDoc?.name, movieClubData.name);
    assert.notEqual(movieClubDoc?.numMembers, movieClubData.numMembers);
    assert.notEqual(movieClubDoc?.ownerId, movieClubData.ownerId);
    assert.notEqual(movieClubDoc?.ownerName, movieClubData.ownerName);
    assert.equal(movieClubDoc?.timeInterval, movieClubData.timeInterval);
  });

  it("should error if user doesn't own the club", async () => {
    try {
      auth.uid = "wrong-uid";
      await wrapped({ data: movieClubData, auth: auth });
      assert.fail("Expected error not thrown");
    } catch (error: any) {
      assert.match(
        error.message,
        /The user is not the owner of the Movie Club./,
      );
    }
  });

  it("should error without required fields", async () => {
    try {
      await wrapped({ data: {}, auth: auth });
      assert.fail("Expected error not thrown");
    } catch (error: any) {
      assert.match(error.message, /The function must be called with id./);
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
