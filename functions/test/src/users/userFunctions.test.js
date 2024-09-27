"use strict";

const assert = require("assert");
const { test } = require("test/testHelper");
const { firestore, firebaseAdmin } = require("firestore");
const { populateUserData } = require("mocks");
const { users: { createUserWithEmail, createUserWithSignInProvider, updateUser } } = require("index");

describe("User Functions", () => {
  describe("createUserWithEmail", () => {
    const createUserWithEmailWrapped = test.wrap(createUserWithEmail);

    let userId;
    let userData;

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

      assert(userDoc.name == userData.name);
      assert(userDoc.image == userData.image);
      assert(userDoc.bio == userData.bio);
      assert(userDoc.email == userData.email);
    });

    it("should error when email already exists", async () => {
      try {
        await createUserWithEmailWrapped(userData);

        userData.name = "Test User 2";
        await createUserWithEmailWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /The email address is already in use by another account./);
      };
    });

    it("should error when user name already exists", async () => {
      try {
        await createUserWithEmailWrapped(userData);

        userData.email = "test2@email.com";
        await createUserWithEmailWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /name Test User already exists./);
      };
    });

    it("should error without required fields", async () => {
      try {
        await createUserWithEmailWrapped({})
        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /The function must be called with email, name, password./);
      };
    });
  });

  describe("createUserWithSignInProvider", () => {
    const createUserWithSignInProviderWrapped = test.wrap(createUserWithSignInProvider);

    let userId;
    let userData;

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
        password: userData.password,
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

      assert(userDoc.name == userData.name);
      assert(userDoc.image == userData.image);
      assert(userDoc.bio == userData.bio);
      assert(userDoc.email == userData.email);
    });

    it("should error when email doesn't exist in auth", async () => {
      try {
        userData.email = "nonexistant@email.com"
        await createUserWithSignInProviderWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /email does not exist/);
      };
    });

    it("should error when email already exists", async () => {
      try {
        await createUserWithSignInProviderWrapped(userData);

        userData.name = "Test User 2";
        await createUserWithSignInProviderWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /email test@email.com already exists./);
      };
    });

    it("should error when user name already exists", async () => {
      try {
        await createUserWithSignInProviderWrapped(userData);

        userData.email = "test2@email.com";

        await firebaseAdmin.auth().createUser({
          email: userData.email,
          password: userData.password,
          displayName: userData.name
        });

        await createUserWithSignInProviderWrapped(userData);

        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /name Test User already exists./);
      };
    });

    it("should error without required fields", async () => {
      try {
        await createUserWithSignInProviderWrapped({})
        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /The function must be called with email, name./);
      };
    });
  });

  describe("updateUser", () => {
    const updateUserWrapped = test.wrap(updateUser);

    let user;
    let userData;

    beforeEach(async () => {
      user = await populateUserData();

      userData = {
        id: user.id,
        name: "Updated test User",
        image: "Updated test Image",
        bio: "Updated test Bio"
      };
    });

    it("should update an existing User", async () => {
      await updateUserWrapped(userData);
      const snap = await firestore.collection("users").doc(user.id).get();
      const userDoc = snap.data();

      assert(userDoc.id == userData.id);
      assert(userDoc.name == userData.name);
      assert(userDoc.image == userData.image);
      assert(userDoc.bio == userData.bio);
    });

    it("should error without required fields", async () => {
      try {
        await updateUserWrapped({})
        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /The function must be called with id./);
      };
    });
  });
});