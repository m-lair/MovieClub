"use strict";

const functions = require("firebase-functions");
const { db } = require("firestore");
const { verifyRequiredFields } = require("utilities");

exports.createMovieClub = functions.https.onCall(async (data, context) => {
  const requiredFields = ["name", "ownerID", "ownerName", "isPublic", "timeInterval", "bannerUrl"];
  verifyRequiredFields(data, requiredFields);

  try {
    const movieClubRef = db.collection("movieclubs");

    const movieClubData = {
      name: data.name,
      ownerID: data.ownerID,
      ownerName: data.ownerName,
      isPublic: data.isPublic,
      timeInterval: data.timeInterval,
      bannerUrl: data.bannerUrl
    };

    const movieClub = await movieClubRef.add(movieClubData);

    console.log("Movie Club created successfully!");

    return movieClub;
  } catch (error) {
    console.error("Error creating Movie Club:", error);
  };
});

exports.updateMovieClub = functions.https.onCall(async (data, context) => {
  const requiredFields = ["movieClubId", "ownerID"];
  verifyRequiredFields(data, requiredFields);

  try {
    const movieClubRef = db.collection("movieclubs").doc(data.movieClubId);
    const movieClubSnap = await movieClubRef.get();
    const movieClub = movieClubSnap.data();

    // TODO
    // Is this a good way to check? Whats stopping someone from stealing the owner's user id
    // ie via a comment they posted and passing that through the request?
    // Should we allow users to change the owner of a Movie Club?
    if (data.ownerID != movieClub.ownerID) {
      throw new functions.https.HttpsError('permission-denied', 'ownerID does not match movieClub.ownerID');
    };

    const movieClubData = {
      ...(data.name && { name: data.name }),
      ...(data.ownerID && { ownerID: data.ownerID }),
      ...(data.ownerName && { ownerName: data.ownerName }),
      ...(data.isPublic != undefined && { isPublic: data.isPublic }),
      ...(data.timeInterval && { timeInterval: data.timeInterval }),
      ...(data.bannerUrl && { bannerUrl: data.bannerUrl }),
    };

    await movieClubRef.update(movieClubData);

    console.log("Movie Club updated successfully!");
  } catch (error) {
    console.error("Error updating Movie Club:", error);
    throw error
  };
});