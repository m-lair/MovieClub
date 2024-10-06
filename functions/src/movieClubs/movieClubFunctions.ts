import * as functions from "firebase-functions";
import { firestore } from "firestore";
import { handleCatchHttpsError, logVerbose, throwHttpsError, verifyAuth, verifyRequiredFields } from "helpers";
import { MovieClubData, UpdateMovieClubData } from "./movieClubTypes";
import { CallableRequest } from "firebase-functions/https";
import { MOVIE_CLUBS } from "src/utilities/collectionNames";

exports.createMovieClub = functions.https.onCall(async (request: CallableRequest<MovieClubData>) => {
  try {
    const { data, auth } = request;

    const { uid } = verifyAuth(auth);

    const requiredFields = ["bannerUrl", "description", "image", "isPublic", "name", "ownerName", "timeInterval"];
    verifyRequiredFields(request.data, requiredFields);

    const movieClubRef = firestore.collection(MOVIE_CLUBS);

    const movieClubData: MovieClubData = {
      bannerUrl: data.bannerUrl,
      description: data.description,
      image: data.image,
      isPublic: data.isPublic,
      name: data.name,
      numMembers: 1,
      ownerId: uid,
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

exports.updateMovieClub = functions.https.onCall(async (request: CallableRequest<UpdateMovieClubData>) => {
  try {
    const { data, auth } = request;

    const { uid } = verifyAuth(auth);

    const requiredFields = ["id"];
    verifyRequiredFields(request.data, requiredFields);

    const movieClubRef = firestore.collection(MOVIE_CLUBS).doc(request.data.id);

    const movieClubSnap = await movieClubRef.get();
    const movieClubData = movieClubSnap.data();

    if (movieClubData?.ownerId !== uid) {
      throwHttpsError("permission-denied", "The user is not the owner of the Movie Club.");
    }

    const movieClubUpdateData = {
      ...(data.bannerUrl && { bannerUrl: data.bannerUrl }),
      ...(data.description && { description: data.description }),
      ...(data.image && { image: data.image }),
      ...(data.isPublic != undefined && { isPublic: data.isPublic }),
      ...(data.name && { name: data.name }),
      ...(data.timeInterval && { timeInterval: data.timeInterval })
    };

    await movieClubRef.update(movieClubUpdateData);

    logVerbose("Movie Club updated successfully!");
  } catch (error) {
    handleCatchHttpsError(`Error updating Movie Club ${request.data.id}:`, error)
  };
});