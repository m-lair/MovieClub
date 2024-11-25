import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";

import {
  handleCatchHttpsError,
  logVerbose,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { verifyMembership } from "src/users/memberships/membershipHelpers";
import { MovieData } from "./movieTypes";
import { MovieClubData } from "../movieClubTypes";
import { SuggestionData } from "../suggestions/suggestionTypes";
import { getMovieClubDocRef } from "../movieClubHelpers";
import { getActiveMovieDoc, getMovieRef } from "./movieHelpers";
import { getNextSuggestionDoc } from "../suggestions/suggestionHelpers";


// Cloud Function to rotate the movie
exports.rotateMovie = functions.https.onCall(
  async (request: CallableRequest<{ clubId: string }>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);
      const requiredFields = ["clubId"];
      const { clubId } = data;
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, clubId);

      const activeMovieDoc = await getActiveMovieDoc(clubId);

      if (activeMovieDoc) {
        const activeMovie = activeMovieDoc.data() as MovieData;

        if (new Date() < activeMovie.endDate) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'The current movie\'s watch period has not ended.'
          );
        }

        // Mark the current movie as 'completed'
        await activeMovieDoc.ref.update({ status: 'archived' });
      }

      // Retrieve the next suggestion
      const nextSuggestionDoc = await getNextSuggestionDoc(clubId);
      if (!nextSuggestionDoc) {
        logVerbose("No suggestions available to rotate to.");
        return { success: false, message: "No suggestions available." };
      }


      const suggestionData = nextSuggestionDoc.data() as SuggestionData;

      // Set up the new movie's watch period
      const clubDocRef = getMovieClubDocRef(clubId);
      const clubDoc = await clubDocRef.get();
      const clubData = clubDoc.data() as MovieClubData;

      const startDate = new Date();
      const endDate = new Date(startDate.getTime() + clubData.timeInterval * 7 * 24 * 60 * 60 * 1000);


      const movieData: MovieData = {
        ...suggestionData,
        likes: 0,
        dislikes: 0,
        numCollected: 0,
        numComments: 0,
        imdbId: suggestionData.imdbId,
        status: 'active',
        startDate: startDate,
        endDate: endDate,
        collectedBy: [],
        likedBy: [],
        dislikedBy: []
      };

      // Add the new movie as 'active'
      const movieCollectionRef = getMovieRef(clubId);
      await movieCollectionRef.add(movieData);

      // Delete the suggestion
      await nextSuggestionDoc.ref.delete();

      // Update movieEndDate in the movieClub document
      await clubDocRef.update({ movieEndDate: endDate });

      logVerbose('Movie rotated successfully!');
      return { success: true };
    } catch (error) {
      console.error('Error rotating movie:', error);
      handleCatchHttpsError('Error rotating movie:', error);
    }
  }
);