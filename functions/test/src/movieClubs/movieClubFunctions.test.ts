const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { firestore } from "firestore";
import { movieClubs } from "index";
import { MovieClubData, UpdateMovieClubData } from "src/movieClubs/movieClubTypes";
import { populateMovieClubData } from "mocks";
import { populateUserData, UserDataMock } from "test/mocks/user";
import { MovieClubMock } from "test/mocks/movieclub";

// @ts-ignore
// TODO: Figure out why ts can't detect the export on this
const { createMovieClub, updateMovieClub } = movieClubs;

describe("createMovieClub", () => {
  const wrapped = firebaseTest.wrap(createMovieClub);

  let user: UserDataMock;
  let movieClubData: MovieClubData;
  let movieClub: UpdateMovieClubData;

  beforeEach(async () => {
    user = await populateUserData();
    const userId = user.id || "test-user-id";
    const username = user.name || "test-user-name";

    movieClubData = {
      bannerUrl: "Test Banner Url",
      description: "Test Description",
      image: "Test Image",
      isPublic: true,
      name: "Test Club",
      numMembers: 1,
      ownerId: userId,
      ownerName: username,
      timeInterval: "Test Interval",
    };
  });

  it("should create a new Movie Club", async () => {
    movieClub = await wrapped(movieClubData)
    const snap = await firestore.collection("movieclubs").doc(movieClub.id).get()
    const movieClubDoc = snap.data();

    assert.equal(movieClubDoc?.bannerUrl, movieClubData.bannerUrl);
    assert.equal(movieClubDoc?.description, movieClubData.description);
    assert.equal(movieClubDoc?.image, movieClubData.image);
    assert.equal(movieClubDoc?.isPublic, movieClubData.isPublic);
    assert.equal(movieClubDoc?.name, movieClubData.name);
    assert.equal(movieClubDoc?.numMembers, movieClubData.numMembers);
    assert.equal(movieClubDoc?.ownerId, movieClubData.ownerId);
    assert.equal(movieClubDoc?.ownerName, movieClubData.ownerName);
    assert.equal(movieClubDoc?.timeInterval, movieClubData.timeInterval);
  });

  it("should error without required fields", async () => {
    try {
      await wrapped({})
      assert.fail('Expected error not thrown');
    } catch (error: any) {
      assert.match(error.message, /The function must be called with bannerUrl, description, image, isPublic, name, ownerId, ownerName, timeInterval./);
    };
  });
});

describe("updateMovieClub", () => {
  const wrapped = firebaseTest.wrap(updateMovieClub)

  let user: UserDataMock;
  let movieClubData: UpdateMovieClubData;
  let movieClub: MovieClubMock;

  beforeEach(async () => {
    user = await populateUserData();
    movieClub = await populateMovieClubData({ id: "1", ownerId: user.id, ownerName: user.name });

    movieClubData = {
      id: movieClub.id,
      description: "Updated Description",
      isPublic: false,
      image: "Updated Image",
      name: "Updated Test Club",
      numMembers: 2,
      ownerId: "Not Updated ownerId",
      ownerName: "Not Updated ownerName",
      timeInterval: "Updated test interval",
      bannerUrl: "Updated test banner URL",
    };
  });

  it("should update an existing Movie Club", async () => {
    await wrapped(movieClubData)
    const snap = await firestore.collection("movieclubs").doc(movieClub.id).get()
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

  it("should error without required fields", async () => {
    try {
      await wrapped({})
      assert.fail('Expected error not thrown');
    } catch (error: any) {
      assert.match(error.message, /The function must be called with id/);
    };
  });

  it.skip("should not allow a user who does not own the movie club to update it", async () => {
    try {
      await wrapped({
        movieClubId: movieClub.id,
        name: "Updated Test Club",
        ownerId: "wrong-user-id",
      })
      assert.fail('Expected error not thrown');
    } catch (error: any) {
      assert.match(error.message, /ownerId does not match movieClub.ownerId/);
    };
  });
});
