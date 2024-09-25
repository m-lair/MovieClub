"use strict";

const assert = require("assert");
const { test } = require("test/testHelper");
const { db, admin } = require("firestore");
const { populateUserData } = require("mocks");
const { users: { createUser, updateUser } } = require("index");

describe("User Functions", () => {
  describe("createUser", () => {
    const createUserWrapped = test.wrap(createUser);

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
    });

    afterEach(async () => {
      const result = await admin.auth().listUsers();
      const users = result.users.map(user => user.uid);

      await admin.auth().deleteUsers(users);
    });

    it("should create a new User when email exists in auth via alt sign-in (ie apple/gmail)", async () => {
      userId = await createUserWrapped(userData);

      const snap = await db.collection("users").doc(userId).get();
      const userDoc = snap.data();

      assert(userDoc.name == userData.name);
      assert(userDoc.image == userData.image);
      assert(userDoc.bio == userData.bio);
      assert(userDoc.email == userData.email);
    });

    it("should create a new User when email doesn't exist in auth", async () => {
      userId = await createUserWrapped(userData);

      const snap = await db.collection("users").doc(userId).get();
      const userDoc = snap.data();

      assert(userDoc.name == userData.name);
      assert(userDoc.image == userData.image);
      assert(userDoc.bio == userData.bio);
      assert(userDoc.email == userData.email);
    });

    it("should error when email already exists", async () => {
      try {
        await createUserWrapped(userData);
        await createUserWrapped({ email: userData.email, name: "Test User 2" });

        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /The email address is already in use by another account./);
      };
    });

    it("should error when user name already exists", async () => {
      try {
        await createUserWrapped(userData);
        await createUserWrapped({ email: "test2@email.com", name: userData.name });

        assert.fail("Expected error not thrown");
      } catch (error) {
        assert.match(error.message, /name Test User already exists./);
      };
    });

    it("should error without required fields", async () => {
      try {
        await createUserWrapped({})
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
        bio: "Updated test Bio",
        email: "updatedTest@email.com"
      };
    });

    it("should update an existing User", async () => {
      await updateUserWrapped(userData);
      const snap = await db.collection("users").doc(user.id).get();
      const userDoc = snap.data();

      assert(userDoc.id == userData.id);
      assert(userDoc.name == userData.name);
      assert(userDoc.image == userData.image);
      assert(userDoc.bio == userData.bio);
      assert(userDoc.email == userData.email);
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