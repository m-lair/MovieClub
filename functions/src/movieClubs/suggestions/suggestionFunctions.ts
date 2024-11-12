import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";
import { verifyMembership } from "src/users/memberships/membershipHelpers";
import { CreateMovieClubSuggestionData, DeleteMovieClubSuggestionData } from "./suggestionTypes";
import { getMovieClubSuggestionRef } from "./suggestionHelpers";
import { getMovieClubSuggestionDocRef } from "./suggestionHelpers";
import { getMovieRef, getMovieClubMovieStatus } from "../movies/movieHelpers";
import { getMovieClubDocRef } from "../../movieClubs/movieClubHelpers";

import {
  handleCatchHttpsError,
  logVerbose,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { MovieClubData } from "../movieClubTypes";
import { MovieData } from "../movies/movieTypes";

exports.createMovieClubSuggestion = functions.https.onCall(
  async (request: CallableRequest<CreateMovieClubSuggestionData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);
      const requiredFields = ["imdbId", "userName"];
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, data.clubId);

      const suggestionCollection = getMovieClubSuggestionRef(data.clubId);
      
      // Create base suggestion data
      const suggestionData: CreateMovieClubSuggestionData = {
        userName: data.userName,
        userImage: data.userImage,
        imdbId: data.imdbId,
        userId: data.userId,
        clubId: data.clubId,
        createdAt: new Date()
      };

      // Check if suggestion collection is empty
      const suggestionsSnapshot = suggestionCollection.count;
      
      if (suggestionsSnapshot.length === 0) {
        const activeMovieRef = await getMovieClubMovieStatus(data.clubId);
        if (activeMovieRef.empty) {
          setMovieFromSuggestion(uid, data.clubId, suggestionData);
      } else {
        // Otherwise, add to suggestions as normal
        console.log("Suggestion is empty but there is an active movie");
        await suggestionCollection.doc(uid).set(suggestionData);
        return { success: true };
      }
      
      return { success: true };
    }
    } catch (error) {
      console.log(error)
      handleCatchHttpsError("Error creating Suggestion:", error);
    }
  }
);

export const setMovieFromSuggestion = async (uid: string, movieClubId: string, suggestionData: CreateMovieClubSuggestionData) => {
  const movieCollectionRef = getMovieRef(movieClubId);
  const clubDoc = await getMovieClubDocRef(movieClubId).get();
  const club = clubDoc.data() as MovieClubData;

  const startDate = new Date();
  const endDate = new Date();

  endDate.setDate(endDate.getDate() + (Number(club.timeInterval) * 7));

  const movieData: MovieData = {
    ...suggestionData,
    likes: 0,
    dislikes: 0,
    numCollected: 0,
    numComments: 0,
    status: 'active',
    startDate: startDate,
    endDate: endDate
  };
  
  await movieCollectionRef.add(movieData);
};

exports.deleteMovieClubSuggestion = functions.https.onCall(
  async (request: CallableRequest<DeleteMovieClubSuggestionData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);
      
      console.log(data);
      const suggestionRef = getMovieClubSuggestionDocRef(uid, data.clubId);
      await suggestionRef.delete();

      logVerbose("Suggestion deleted successfully!");
      return { success: true };
    } catch (error) {
      console.log(error)
      handleCatchHttpsError("Error deleting Suggestion:", error);
    }
  }
);