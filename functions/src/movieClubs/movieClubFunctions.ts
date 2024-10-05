import * as functions from "firebase-functions";
import { firestore } from "firestore";
import { handleCatchHttpsError, logVerbose, verifyRequiredFields } from "helpers";
import { MovieClubData, UpdateMovieClubData } from "./movieClubTypes";
import { CallableRequest } from "firebase-functions/https";
import { MOVIE_CLUBS } from "src/utilities/collectionNames";

exports.createMovieClub = functions.https.onCall(async (request: CallableRequest<MovieClubData>) => {
  try {
    const requiredFields = ["bannerUrl", "description", "image", "isPublic", "name", "ownerId", "ownerName", "timeInterval"];
    verifyRequiredFields(request.data, requiredFields);

    const movieClubRef = firestore.collection(MOVIE_CLUBS);

    const movieClubData: MovieClubData = {
      bannerUrl: request.data.bannerUrl,
      description: request.data.description,
      image: request.data.image,
      isPublic: request.data.isPublic,
      name: request.data.name,
      numMembers: 1,
      ownerId: request.data.ownerId,
      ownerName: request.data.ownerName,
      timeInterval: request.data.timeInterval,
      createdAt: Date.now()
    };

    const movieClub = await movieClubRef.add(movieClubData);

    logVerbose("Movie Club created successfully!");

    return movieClub;
  } catch (error) {
    handleCatchHttpsError("Error creating Movie Club:", error)
  };
});

exports.updateMovieClub = functions.https.onCall(async (request: CallableRequest<UpdateMovieClubData>) => {
  try {
    const requiredFields = ["id"];
    verifyRequiredFields(request.data, requiredFields);

    const movieClubRef = firestore.collection(MOVIE_CLUBS).doc(request.data.id);

    const movieClubData = {
      ...(request.data.bannerUrl && { bannerUrl: request.data.bannerUrl }),
      ...(request.data.description && { description: request.data.description }),
      ...(request.data.image && { image: request.data.image }),
      ...(request.data.isPublic != undefined && { isPublic: request.data.isPublic }),
      ...(request.data.name && { name: request.data.name }),
      ...(request.data.timeInterval && { timeInterval: request.data.timeInterval })
    };

    await movieClubRef.update(movieClubData);

    logVerbose("Movie Club updated successfully!");
  } catch (error) {
    handleCatchHttpsError(`Error updating Movie Club ${request.data.id}:`, error)
  };
});