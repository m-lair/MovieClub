// @ts-nocheck

"use strict";

import * as functions from "firebase-functions";
import { firestore } from "firestore";
import { handleCatchHttpsError, logVerbose, verifyRequiredFields } from "helpers";

exports.createMovieClub = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["name", "ownerId", "ownerName", "isPublic", "timeInterval", "bannerUrl"];
    verifyRequiredFields(data, requiredFields);

    const movieClubRef = firestore.collection("movieclubs");

    const movieClubData = {
      name: data.name,
      ownerId: data.ownerId,
      ownerName: data.ownerName,
      isPublic: data.isPublic,
      timeInterval: data.timeInterval,
      bannerUrl: data.bannerUrl
    };

    const movieClub = await movieClubRef.add(movieClubData);

    logVerbose("Movie Club created successfully!");

    return movieClub;
  } catch (error) {
    handleCatchHttpsError("Error creating Movie Club:", error)
  };
});

exports.updateMovieClub = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["movieClubId", "ownerId"];
    verifyRequiredFields(data, requiredFields);

    const movieClubRef = firestore.collection("movieclubs").doc(data.movieClubId);
    const movieClubSnap = await movieClubRef.get();
    const movieClub = movieClubSnap.data();

    // TODO
    // Is this a good way to check? Whats stopping someone from stealing the owner's user id
    // ie via a comment they posted and passing that through the request?
    // Should we allow users to change the owner of a Movie Club?
    if (data.ownerId != movieClub.ownerId) {
      throw new functions.https.HttpsError('permission-denied', 'ownerId does not match movieClub.ownerId');
    };

    const updateOwnerId = data.updateOwnerId || false;

    const movieClubData = {
      ...(data.name && { name: data.name }),
      ...(updateOwnerId && { ownerId: updateOwnerId }),
      ...(data.ownerName && { ownerName: data.ownerName }),
      ...(data.isPublic != undefined && { isPublic: data.isPublic }),
      ...(data.timeInterval && { timeInterval: data.timeInterval }),
      ...(data.bannerUrl && { bannerUrl: data.bannerUrl }),
    };

    await movieClubRef.update(movieClubData);

    logVerbose("Movie Club updated successfully!");
  } catch (error) {
    handleCatchHttpsError(`Error updating Movie Club ${data.movieClubId}:`, error)
  };
});