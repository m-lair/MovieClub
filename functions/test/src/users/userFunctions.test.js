"use strict";

const assert = require("assert");
const { test } = require("test/testHelper");
const { db } = require("firestore");
const { populateUserData } = require("mocks");
const { users: { createUser, updateUser } } = require("index");

describe("createUser", () => {
  const wrapped = test.wrap(createUser);

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

  afterEach(() => {
    test.cleanup();
  });

  it("should create a new User when email exists in auth via alt sign-in (ie apple/gmail)", async () => {
    userId = await wrapped(userData);

    const snap = await db.collection("users").doc(userId).get();
    const userDoc = snap.data();

    assert(userDoc.name == userData.name);
    assert(userDoc.image == userData.image);
    assert(userDoc.bio == userData.bio);
    assert(userDoc.email == userData.email);
  });

  it("should create a new User when email doesn't exist in auth", async () => {
    userId = await wrapped(userData);

    const snap = await db.collection("users").doc(userId).get();
    const userDoc = snap.data();

    assert(userDoc.name == userData.name);
    assert(userDoc.image == userData.image);
    assert(userDoc.bio == userData.bio);
    assert(userDoc.email == userData.email);
  });

  it("should error without required fields", async () => {
    try {
      await wrapped({})
      assert.fail("Expected error not thrown");
    } catch (error) {
      assert.match(error.message, /The function must be called with email, name./);
    };
  });
});

describe("updateUser", () => {
  const wrapped = test.wrap(updateUser);

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

  afterEach(() => {
    test.cleanup();
  });

  it("should update an existing User", async () => {
    await wrapped(userData);
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
      await wrapped({})
      assert.fail("Expected error not thrown");
    } catch (error) {
      assert.match(error.message, /The function must be called with id./);
    };
  });
});