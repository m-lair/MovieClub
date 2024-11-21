import * as functions from "firebase-functions";
import { firestore } from "firestore";
import {
  handleCatchHttpsError,
  logVerbose,
  throwHttpsError,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { MovieClubData, UpdateMovieClubData } from "./movieClubTypes";
import { CallableRequest } from "firebase-functions/https";
import { MOVIE_CLUBS } from "src/utilities/collectionNames";

exports.createMovieClub = functions.https.onCall(
  async (request: CallableRequest<MovieClubData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = [
        //"bannerUrl",
        "description",
        "isPublic",
        "name",
        "ownerName",
        "timeInterval",
      ];
      verifyRequiredFields(request.data, requiredFields);

      const movieClubRef = firestore.collection(MOVIE_CLUBS);

      const movieClubData: MovieClubData = {
        description: data.description,
        isPublic: data.isPublic,
        name: data.name,
        numMembers: 1,
        ownerId: uid,
        ownerName: data.ownerName,
        timeInterval: data.timeInterval,
        createdAt: Date.now(),
      };

      logVerbose("Adding movie club to Firestore...");
      const movieClub = await movieClubRef.add(movieClubData);
      await movieClubRef.doc(movieClub.id).collection("members").doc(uid).set({
        username: data.ownerName,
        createdAt: Date.now(),
      });

      await firestore
      .collection("users")
      .doc(uid).collection("memberships")
      .doc(movieClub.id).set({
        movieClubName: movieClubData.name,
        createdAt: Date.now(),
      });

      return movieClub.id;
    } catch (error) {
      handleCatchHttpsError("Error creating Movie Club:", error);
    }
  },
);

exports.updateMovieClub = functions.https.onCall(
  async (request: CallableRequest<UpdateMovieClubData>) => {
    try {
      const { data, auth } = request;
      console.log("data", data);
      const { uid } = verifyAuth(auth);

      const requiredFields = ["id"];
      verifyRequiredFields(request.data, requiredFields);

      const movieClubRef = firestore
        .collection(MOVIE_CLUBS)
        .doc(request.data.id);

      const movieClubSnap = await movieClubRef.get();
      const movieClubData = movieClubSnap.data();

      if (movieClubData?.ownerId !== uid) {
        throwHttpsError(
          "permission-denied",
          "The user is not the owner of the Movie Club.",
        );
      }

      const movieClubUpdateData = {
        ...(data.description && { description: data.description }),
        ...(data.isPublic != undefined && { isPublic: data.isPublic }),
        ...(data.name && { name: data.name }),
        ...(data.timeInterval && { timeInterval: data.timeInterval }),
      };

      await movieClubRef.update(movieClubUpdateData);

      return { success: true };
    } catch (error) {
      console.log(error)
      handleCatchHttpsError("Error creating Suggestion:", error);
    }
    }
);
