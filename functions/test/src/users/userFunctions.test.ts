const assert = require("assert");
import { firebaseTest } from "test/testHelper";
import { firestore, firebaseAdmin } from "firestore";
import { users } from "index";
import { CreateUserWithEmailData, CreateUserWithOAuthData, UpdateUserData } from "src/users/userTypes";
import { populateUserData, UserDataMock } from "test/mocks/user";

// @ts-ignore
// TODO: Figure out why ts can't detect the export on this
const { createUserWithEmail, createUserWithSignInProvider, updateUser } = users;

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

    afterEach(async () => {
      const result = await firebaseAdmin.auth().listUsers();
      const users = result.users.map(user => user.uid);

      await firebaseAdmin.auth().deleteUsers(users);
    });

    it("should create a new User with email, name and password", async () => {
      userId = await createUserWithEmailWrapped(userData);

      const snap = await firestore.collection("users").doc(userId).get();
      const userDoc = snap.data();

      assert(userDoc?.name == userData.name);
      assert(userDoc?.image == userData.image);
      assert(userDoc?.bio == userData.bio);
      assert(userDoc?.email == userData.email);
    });

    it("should error when email already exists", async () => {
      try {
        await createUserWithEmailWrapped(userData);

        userData.name = "Test User 2";
        await createUserWithEmailWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The email address is already in use by another account./);
      };
    });

    it("should error when user name already exists", async () => {
      try {
        await createUserWithEmailWrapped(userData);

        userData.email = "test2@email.com";
        await createUserWithEmailWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /name Test User already exists./);
      };
    });

    it("should error without required fields", async () => {
      try {
        await createUserWithEmailWrapped({})
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

    afterEach(async () => {
      const result = await firebaseAdmin.auth().listUsers();
      const users = result.users.map(user => user.uid);

      await firebaseAdmin.auth().deleteUsers(users);
    });

    it("should create a new User when email exists in auth via alt sign-in (ie apple/gmail)", async () => {
      userId = await createUserWithSignInProviderWrapped(userData);

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
        await createUserWithSignInProviderWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /email does not exist/);
      };
    });

    it("should error when email already exists", async () => {
      try {
        await createUserWithSignInProviderWrapped(userData);

        userData.name = "Test User 2";
        await createUserWithSignInProviderWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /email test@email.com already exists./);
      };
    });

    it("should error when user name already exists", async () => {
      try {
        await createUserWithSignInProviderWrapped(userData);

        userData.email = "test2@email.com";

        await firebaseAdmin.auth().createUser({
          email: userData.email,
          displayName: userData.name
        });

        await createUserWithSignInProviderWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /name Test User already exists./);
      };
    });

    it("should error without required fields", async () => {
      try {
        await createUserWithSignInProviderWrapped({})
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
      user = await populateUserData({});

      userData = {
        id: user.id,
        name: "Updated test User",
        image: "Updated test Image",
        bio: "Updated test Bio"
      };
    });

    it("should update an existing User", async () => {
      await updateUserWrapped(userData);
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
        await updateUserWrapped({})
        assert.fail("Expected error not thrown");
      } catch (error: any) {
        assert.match(error.message, /The function must be called with id./);
      };
    });
  });
});