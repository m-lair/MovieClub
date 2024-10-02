const assert = require("assert");
import { test } from "test/testHelper";
import { firestore } from "firestore";
import { populateUserData, populateMovieClubData } from "mocks";
import { movieClubs } from "index";
import { MovieClubData, UpdateMovieClubData } from "src/movieClubs/movieClubTypes";
import { UpdateUserData } from "src/users/userTypes";

// @ts-ignore
// TODO: Figure out why ts can't detect the export on this
const { createMovieClub, updateMovieClub } = movieClubs;

describe("createMovieClub", () => {
  const wrapped = test.wrap(createMovieClub);

  let user: UpdateUserData;
  let movieClubData: MovieClubData;
  let movieClub;

  beforeEach(async () => {
    user = await populateUserData();

    movieClubData = {
      bannerUrl: "test",
      description: "Test Description",
      image: "Test Image",
      isPublic: true,
      name: "Test Club",
      ownerId: user.id,
      ownerName: user.name,
      timeInterval: "test",
    };
  });

  it("should create a new Movie Club", async () => {
    movieClub = await wrapped(movieClubData)
    const snap = await firestore.collection("movieclubs").doc(movieClub.id).get()
    const movieClubDoc = snap.data();

    assert(movieClubDoc?.name == movieClubData.name);
    assert(movieClubDoc?.ownerId == movieClubData.ownerId);
    assert(movieClubDoc?.ownerName == movieClubData.ownerName);
    assert(movieClubDoc?.isPublic == movieClubData.isPublic);
    assert(movieClubDoc?.timeInterval == movieClubData.timeInterval);
    assert(movieClubDoc?.bannerUrl == movieClubData.bannerUrl);
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
  const wrapped = test.wrap(updateMovieClub)

  let user: UpdateUserData;
  let movieClubData: UpdateMovieClubData;
  let movieClub: UpdateMovieClubData;

  beforeEach(async () => {
    user = await populateUserData();
    movieClub = await populateMovieClubData({ id: "1", ownerId: user.id, ownerName: user.name });
    
    movieClubData = {
      id: movieClub.id,
      description: "Updated Description",
      isPublic: false,
      image: "Updated Image",
      name: "Updated Test Club",
      ownerId: user.id,
      ownerName: user.name,
      timeInterval: "updated test interval",
      bannerUrl: "updated test banner URL",
    };
  });

  it("should update an existing Movie Club", async () => {
    await wrapped(movieClubData)
    const snap = await firestore.collection("movieclubs").doc(movieClub.id).get()
    const movieClubDoc = snap.data();

    assert(movieClubDoc?.bannerUrl == movieClubData.bannerUrl);
    assert(movieClubDoc?.description == movieClubData.description);
    assert(movieClubDoc?.image == movieClubData.image);
    assert(movieClubDoc?.isPublic == movieClubData.isPublic);
    assert(movieClubDoc?.name == movieClubData.name);
    assert(movieClubDoc?.ownerId == movieClubData.ownerId);
    assert(movieClubDoc?.ownerName == movieClubData.ownerName);
    assert(movieClubDoc?.timeInterval == movieClubData.timeInterval);
  });

  it("should error without required fields", async () => {
    try {
      await wrapped({})
      assert.fail('Expected error not thrown');
    } catch (error: any) {
      assert.match(error.message, /The function must be called with id, ownerId./);
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
