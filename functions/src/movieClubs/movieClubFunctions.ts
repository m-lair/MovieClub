import * as functions from "firebase-functions";
import { firestore, firebaseAdmin } from "firestore";
import { handleCatchHttpsError, logVerbose, verifyRequiredFields } from "helpers";
import { MovieClubData, UpdateMovieClubData } from "./movieClubTypes";

exports.createMovieClub = functions.https.onCall(async (data: MovieClubData, context) => {
  try {
    const requiredFields = ["bannerUrl", "description", "image", "isPublic", "name", "ownerId", "ownerName", "timeInterval"];
    verifyRequiredFields(data, requiredFields);

    const movieClubRef = firestore.collection("movieclubs");

    const movieClubData: MovieClubData = {
      bannerUrl: data.bannerUrl,
      description: data.description,
      image: data.image,
      isPublic: data.isPublic,
      name: data.name,
      ownerId: data.ownerId,
      ownerName: data.ownerName,
      timeInterval: data.timeInterval,
      createdAt: Date.now()
    };

    const movieClub = await movieClubRef.add(movieClubData);

    logVerbose("Movie Club created successfully!");

    return movieClub;
  } catch (error) {
    handleCatchHttpsError("Error creating Movie Club:", error)
  };
});

exports.updateMovieClub = functions.https.onCall(async (data: UpdateMovieClubData, context) => {
  try {
    const requiredFields = ["id", "ownerId"];
    verifyRequiredFields(data, requiredFields);

    const movieClubRef = firestore.collection("movieclubs").doc(data.id);

    const movieClubData = {
      ...(data.bannerUrl && { bannerUrl: data.bannerUrl }),
      ...(data.description && { description: data.description }),
      ...(data.image && { image: data.image }),
      ...(data.isPublic != undefined && { isPublic: data.isPublic }),
      ...(data.name && { name: data.name }),
      ...(data.timeInterval && { timeInterval: data.timeInterval })
    };

    await movieClubRef.update(movieClubData);

    logVerbose("Movie Club updated successfully!");
  } catch (error) {
    handleCatchHttpsError(`Error updating Movie Club ${data.id}:`, error)
  };
});