const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { firestore, firebaseAdmin } from "firestore";
import { users } from "index";
import { CreateUserWithEmailData, CreateUserWithOAuthData, UpdateUserData } from "src/users/userTypes";
import { populateUserData, UserDataMock } from "test/mocks/user";
import { MovieClubMock, populateMovieClubData } from "test/mocks/movieclub";
import { AuthData } from "firebase-functions/tasks";

// @ts-ignore
// TODO: Figure out why ts can't detect the export on this
const { createUserWithEmail, createUserWithSignInProvider, joinMovieClub, updateUser } = users;

describe("User Functions", () => {
  describe("createUserWithEmail", () => {
    const createUserWithEmailWrapped = firebaseTest.wrap(createUserWithEmail);

    let userId: string;
    let userData: CreateUserWithEmailData;

    beforeEach(async () => {
      userData = {
        name: "Test User",
        image: "Test Image",
        bio: "Test Bio",
        email: "test@email.com",
        password: "test-password"
      };
    });

    it("should create a new User with email, name and password", async () => {
      userId = await createUserWithEmailWrapped({ data: userData });

      const snap = await firestore.collection("users").doc(userId).get();
      const userDoc = snap.data();

      assert(userDoc?.name == userData.name);
      assert(userDoc?.image == userData.image);
      assert(userDoc?.bio == userData.bio);
      assert(userDoc?.email == userData.email);
    });

    it("should error when email already exists", async () => {
      try {
        await createUserWithEmailWrapped({ data: userData });

        userData.name = "Test User 2";
        await createUserWithEmailWrapped({ data: userData });

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The email address is already in use by another account./);
      };
    });

    it("should error when user name already exists", async () => {
      try {
        await createUserWithEmailWrapped({ data: userData });

        userData.email = "test2@email.com";
        await createUserWithEmailWrapped({ data: userData });

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /name Test User already exists./);
      };
    });

    it("should error without required fields", async () => {
      try {
        await createUserWithEmailWrapped({ data: {} })
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The function must be called with email, name, password./);
      };
    });
  });

  describe("createUserWithSignInProvider", () => {
    const createUserWithSignInProviderWrapped = firebaseTest.wrap(createUserWithSignInProvider);

    let userId: string;
    let userData: CreateUserWithOAuthData;

    beforeEach(async () => {
      userData = {
        name: "Test User",
        image: "Test Image",
        bio: "Test Bio",
        email: "test@email.com",
        signInProvider: "apple"
      };

      await firebaseAdmin.auth().createUser({
        email: userData.email,
        displayName: userData.name
      });
    });

    it("should create a new User when email exists in auth via alt sign-in (ie apple/gmail)", async () => {
      userId = await createUserWithSignInProviderWrapped({ data: userData });

      const snap = await firestore.collection("users").doc(userId).get();
      const userDoc = snap.data();

      assert.equal(userDoc?.name, userData.name);
      assert.equal(userDoc?.image, userData.image);
      assert.equal(userDoc?.bio, userData.bio);
      assert.equal(userDoc?.email, userData.email);
    });

    it("should error when email doesn't exist in auth", async () => {
      try {
        userData.email = "nonexistant@email.com"
        await createUserWithSignInProviderWrapped({ data: userData });

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /email does not exist/);
      };
    });

    it("should error when email already exists", async () => {
      try {
        await createUserWithSignInProviderWrapped({ data: userData });

        userData.name = "Test User 2";
        await createUserWithSignInProviderWrapped({ data: userData });

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /email test@email.com already exists./);
      };
    });

    it("should error when user name already exists", async () => {
      try {
        await createUserWithSignInProviderWrapped({ data: userData });

        userData.email = "test2@email.com";

        await firebaseAdmin.auth().createUser({
          email: userData.email,
          displayName: userData.name
        });

        await createUserWithSignInProviderWrapped({ data: userData });

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /name Test User already exists./);
      };
    });

    it("should error without required fields", async () => {
      try {
        await createUserWithSignInProviderWrapped({ data: {} })
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The function must be called with email, name./);
      };
    });
  });

  describe("updateUser", () => {
    const updateUserWrapped = firebaseTest.wrap(updateUser);

    let user: UserDataMock;
    let userData: UpdateUserData;

    beforeEach(async () => {
      const userMock = await populateUserData();
      user = userMock.user;

      userData = {
        id: user.id,
        name: "Updated test User",
        image: "Updated test Image",
        bio: "Updated test Bio"
      };
    });

    it("should update an existing User", async () => {
      await updateUserWrapped({ data: userData });
      const userId = user.id || "";
      const snap = await firestore.collection("users").doc(userId).get();
      const userDoc = snap.data();

      assert.equal(userDoc?.id, userData.id);
      assert.equal(userDoc?.name, userData.name);
      assert.equal(userDoc?.image, userData.image);
      assert.equal(userDoc?.bio, userData.bio);
    });

    it("should error without required fields", async () => {
      try {
        await updateUserWrapped({ data: {} })
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The function must be called with id./);
      };
    });
  });

  describe("joinMovieClub", () => {
    const joinMovieClubWrapped = firebaseTest.wrap(joinMovieClub);

    let user: UserDataMock;
    let movieClub: MovieClubMock;
    let auth: AuthData;

    beforeEach(async () => {
      const { user: userMock, auth: authMock } = await populateUserData();
      user = userMock;
      auth = authMock!;

      movieClub = await populateMovieClubData()
    });

    it("should create a User Membership collection", async () => {
      await joinMovieClubWrapped({ data: { movieClubId: movieClub.id }, auth: auth })

      const userMembership = await firestore
        .collection("users")
        .doc(user.id)
        .collection("memberships")
        .doc(movieClub.id)
        .get()

      assert.equal(userMembership.id, movieClub.id)
    });

    it("should create a Movie Club Member collection", async () => {
      await joinMovieClubWrapped({ data: { movieClubId: movieClub.id }, auth: auth })

      const movieClubMember = await firestore
        .collection("movieClubs")
        .doc(movieClub.id)
        .collection("members")
        .doc(user.id)
        .get()

      assert.equal(movieClubMember.id, user.id)
    });

    it("should error without required fields", async () => {
      try {
        await joinMovieClubWrapped({ data: {}, auth: auth })
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The function must be called with movieClubId./);
      };
    });

    it("should error without auth", async () => {
      try {
        await joinMovieClubWrapped({ data: {}, auth: undefined })
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /auth object is undefined./);
      };
    });
  });
});