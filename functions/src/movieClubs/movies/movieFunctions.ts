import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";

import {
  handleCatchHttpsError,
  logVerbose,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { verifyMembership } from "src/users/memberships/membershipHelpers";
import { LikeMovieData, MovieData, MovieLikeRequest, MovieReactionData } from "./movieTypes";
import { MovieClubData } from "../movieClubTypes";
import { SuggestionData } from "../suggestions/suggestionTypes";
import { getMovieClubDocRef } from "../movieClubHelpers";
import { getActiveMovieDoc, getMovieDocRef, getMovieRef } from "./movieHelpers";
import { getNextSuggestionDoc } from "../suggestions/suggestionHelpers";
import { firebaseAdmin } from "firestore";


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
        movieClubId: clubId,
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

export const handleMovieReaction = functions.https.onCall(
  async (request: CallableRequest<MovieLikeRequest & { isLike: boolean }>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);
      const { movieId, clubId, isLike } = data;
      
      verifyRequiredFields(data, ["movieId", "clubId", "isLike"]);
      
      const movieRef = getMovieClubDocRef(clubId).collection('movies').doc(movieId);
      
      return await firebaseAdmin.firestore().runTransaction(async (transaction) => {
        const movieDoc = await transaction.get(movieRef);
        
        if (!movieDoc.exists) {
          throw new functions.https.HttpsError('not-found', 'Movie not found in club.');
        }
        
        const movieData = movieDoc.data() as MovieReactionData;
        const updates: Partial<MovieReactionData> = {};
        
        const currentLikedBy = new Set(movieData?.likedBy || []);
        const currentDislikedBy = new Set(movieData?.dislikedBy || []);
        
        if (isLike) {
          if (currentLikedBy.has(uid)) {
            // Remove like
            currentLikedBy.delete(uid);
            updates.likes = (movieData?.likes || 1) - 1;
          } else {
            // Add like
            currentLikedBy.add(uid);
            if (currentDislikedBy.has(uid)) {
              // If was previously disliked, decrement dislikes
              currentDislikedBy.delete(uid);
              updates.dislikes = (movieData?.dislikes || 1) - 1;
            }
            updates.likes = (movieData?.likes || 0) + 1;
          }
        } else {
          if (currentDislikedBy.has(uid)) {
            // Remove dislike
            currentDislikedBy.delete(uid);
            updates.dislikes = (movieData?.dislikes || 1) - 1;
          } else {
            // Add dislike
            currentDislikedBy.add(uid);
            if (currentLikedBy.has(uid)) {
              // If was previously liked, decrement likes
              currentLikedBy.delete(uid);
              updates.likes = (movieData?.likes || 1) - 1;
            }
            updates.dislikes = (movieData?.dislikes || 0) + 1;
          }
        }
        
        updates.likedBy = Array.from(currentLikedBy);
        updates.dislikedBy = Array.from(currentDislikedBy);
        
        transaction.update(movieRef, updates);
        
        logVerbose(`Movie ${isLike ? 'like' : 'dislike'} operation successful`);
        return { 
          success: true,
          newState: {
            liked: currentLikedBy.has(uid),
            disliked: currentDislikedBy.has(uid)
          }
        };
      });
      
    } catch (error) {
      console.error(`Error in movie reaction:`, error);
      handleCatchHttpsError('Error processing movie reaction:', error);
    }
  }
);

exports.likeMovie = functions.https.onCall(
  async (request: CallableRequest<LikeMovieData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);

      const requiredFields = ["movieClubId", "movieId", "name"];
      verifyRequiredFields(data, requiredFields);

      await verifyMembership(uid, data.movieClubId);

      const movieDocRef = getMovieDocRef(data.movieId, data.movieClubId)

      let params = {
        likedBy: firebaseAdmin.firestore.FieldValue.arrayUnion(data.name),
        dislikedBy: firebaseAdmin.firestore.FieldValue.arrayRemove(data.name)
      }

      if (data.undo) {
        params.likedBy = firebaseAdmin.firestore.FieldValue.arrayRemove(data.name)
      }

      await movieDocRef.update(params);

      return { success: true };
    } catch (error) {
      handleCatchHttpsError('Error liking comment:', error);
    }
  }
)

exports.dislikeMovie = functions.https.onCall(
  async (request: CallableRequest<LikeMovieData>) => {

    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);

      const requiredFields = ["movieClubId", "movieId", "name"];
      verifyRequiredFields(data, requiredFields);

      await verifyMembership(uid, data.movieClubId);

      const movieDocRef = getMovieDocRef(data.movieId, data.movieClubId)

      let params = {
        dislikedBy: firebaseAdmin.firestore.FieldValue.arrayUnion(data.name),
        likedBy: firebaseAdmin.firestore.FieldValue.arrayRemove(data.name),
      }

      if (data.undo){
        params.dislikedBy = firebaseAdmin.firestore.FieldValue.arrayRemove(data.name)
      }

      await movieDocRef.update(params);

      return { success: true };
    } catch (error) {
      handleCatchHttpsError('Error disliking comment:', error);
    }
  }
)