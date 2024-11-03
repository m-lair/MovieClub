import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";
import { verifyMembership } from "src/users/memberships/membershipHelpers";
import { CreateMovieClubSuggestionData, DeleteMovieClubSuggestionData } from "./suggestionTypes";
import { getMovieClubSuggestionRef } from "./suggestionHelpers";
import { getMovieClubSuggestionDocRef } from "./suggestionHelpers";
import { getMovieRef } from "../movies/movieHelpers";
import { getMovieClub, getMovieClubDocRef } from "../../movieClubs/movieClubHelpers";

import {
  handleCatchHttpsError,
  logVerbose,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { MovieClubData } from "../movieClubTypes";

exports.createMovieClubSuggestion = functions.https.onCall(
  async (request: CallableRequest<CreateMovieClubSuggestionData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);
      const requiredFields = ["imageUrl", "movieClubId", "title", "username"];
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, data.movieClubId);

      const suggestionRef = getMovieClubSuggestionDocRef(uid, data.movieClubId);
      const suggestionCollection = getMovieClubSuggestionRef(data.movieClubId);
      
      // Create base suggestion data
      const suggestionData = {
        title: data.title,
        username: data.username,
        imdbId: data.imdbId,
        createdAt: Date.now()
      };

      // Check if suggestion collection is empty
      const suggestionsSnapshot = await suggestionCollection.get();
      
      if (suggestionsSnapshot.empty) {
        // If empty, write directly to movies collection with additional fields
        const movieCollectionRef = getMovieRef(data.movieClubId);
        const clubDoc = await getMovieClubDocRef(data.movieClubId).get();
        const club = clubDoc.data() as MovieClubData;
     
        const startDate = Date.now();
        const endDate = new Date();

        endDate.setDate(endDate.getDate() + (Number(club.timeInterval) * 7));

        const movieData = {
          ...suggestionData,
          likes: 0,
          dislikes: 0,
          numCollections: 0,
          status: 'active',
          startDate: startDate,
          endDate: endDate
        };
        
        await movieCollectionRef.add(movieData);
        logVerbose("Movie added directly to movies collection!");
      } else {
        // Otherwise, add to suggestions as normal
        await suggestionRef.set(suggestionData);
        logVerbose("Suggestion created successfully!");
      }
      
      return;
    } catch (error) {
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