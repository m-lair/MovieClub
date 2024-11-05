import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";
import { verifyMembership } from "src/users/memberships/membershipHelpers";
import { CreateMovieClubSuggestionData, DeleteMovieClubSuggestionData } from "./suggestionTypes";
import { getMovieClubSuggestionRef } from "./suggestionHelpers";
import { getMovieClubSuggestionDocRef } from "./suggestionHelpers";
import { getMovieRef } from "../movies/movieHelpers";
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
      const suggestionData = {
        userName: data.userName,
        userImage: data.userImage,
        imdbId: data.imdbId,
        userId: data.userId,
        createdAt: Date.now()
      };

      // Check if suggestion collection is empty
      const suggestionsSnapshot = suggestionCollection.count;
      
      if (suggestionsSnapshot.length === 0) {
        console.log("Suggestion collection is empty!");
        // If empty, write directly to movies collection with additional fields
        const activeMovieRef = await getMovieRef(data.clubId).where("status", "==", "active").get();
        if (activeMovieRef.empty) {
        console.log("no active movies");
        const movieCollectionRef = getMovieRef(data.clubId)
        const clubDoc = await getMovieClubDocRef(data.clubId).get();
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
        logVerbose("Movie added directly to movies collection!");
      
      } else {
        // Otherwise, add to suggestions as normal
        console.log("Suggestion is empty but there is an active movie");
        await suggestionCollection.add(suggestionData);
        logVerbose("Suggestion created successfully!");
      }
      
      return;
    }
    } catch (error) {
      console.log(error)
      handleCatchHttpsError("Error creating Suggestion:", error);
    }
  }
);

exports.deleteUserMovieClubSuggestion = functions.https.onCall(
  async (request: CallableRequest<DeleteMovieClubSuggestionData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);

      const requiredFields = ["movieClubId"];
      verifyRequiredFields(data, requiredFields);

      const suggestionRef = getMovieClubSuggestionDocRef(uid, data.movieClubId);

      await suggestionRef.delete();

      logVerbose("Suggestion deleted successfully!");

      return;
    } catch (error) {
      handleCatchHttpsError("Error deleting Suggestion:", error);
    }
  }
);