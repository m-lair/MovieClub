import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";
import { Timestamp } from 'firebase-admin/firestore';

import {
  handleCatchHttpsError,
  logVerbose,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { verifyMembership } from "src/users/memberships/membershipHelpers";
import { MovieData, MovieLikeRequest, MovieReactionData } from "./movieTypes";
import { MovieClubData } from "../movieClubTypes";
import { SuggestionData } from "../suggestions/suggestionTypes";
import { getMovieClubDocRef } from "../movieClubHelpers";
import { getMovieRef } from "./movieHelpers";
import { getNextSuggestionDoc } from "../suggestions/suggestionHelpers";
import { firebaseAdmin } from "firestore";
import { NotificationType } from "../../notifications/notificationTypes";


// Cloud Function to rotate the movie
exports.rotateMovie = functions.https.onCall(
  async (request: CallableRequest<{ clubId: string }>) => {
    try {
      // Basic validation
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);
      verifyRequiredFields(data, ["clubId"]);
      const { clubId } = data;
      
      // Verify membership
      await verifyMembership(uid, clubId);

      // Create a transaction to ensure data consistency
      return await firebaseAdmin.firestore().runTransaction(async (transaction) => {
        // Get club data for rotation settings
        const clubDocRef = getMovieClubDocRef(clubId);
        const clubDoc = await transaction.get(clubDocRef);
        if (!clubDoc.exists) {
          throw new functions.https.HttpsError('not-found', 'Movie club not found');
        }
        const clubData = clubDoc.data() as MovieClubData;

        // Check for active movie
        const activeMoviesRef = firebaseAdmin
          .firestore()
          .collection(`movieclubs/${clubId}/movies`)
          .where("status", "==", "active");
        const activeMovies = await transaction.get(activeMoviesRef);

        // Variables to track date calculations
        let startDate: Date;

        // Process active movie if it exists
        if (!activeMovies.empty) {
          // Should only have one active movie
          if (activeMovies.size > 1) {
            logVerbose(`Warning: Found ${activeMovies.size} active movies for club ${clubId}`);
          }
          
          const activeMovieDoc = activeMovies.docs[0];
          const activeMovie = activeMovieDoc.data() as MovieData;
          
          // Check if movie is eligible for rotation
          const now = new Date();
          
          // Check if the end date has passed
          const endDateObj = activeMovie.endDate instanceof Date 
            ? activeMovie.endDate 
            : activeMovie.endDate.toDate();
            
          if (now < endDateObj) {
            throw new functions.https.HttpsError(
              'failed-precondition',
              'The current movie\'s watch period has not ended yet.'
            );
          }
          
          // Format the end date (set to 11:59:59 PM)
          const formattedEndDate = new Date(endDateObj);
          formattedEndDate.setHours(23, 59, 59, 999);
          
          // Archive the active movie
          logVerbose(`Archiving movie ${activeMovieDoc.id}`);
          transaction.update(activeMovieDoc.ref, { 
            status: 'archived',
            endDate: Timestamp.fromDate(formattedEndDate)
          });
          
          // Set start date for the next movie to be the day after this movie's end date
          startDate = new Date(formattedEndDate);
          startDate.setDate(startDate.getDate() + 1);
          startDate.setHours(0, 0, 0, 0);  // Set to 12:00:00 AM
        } else {
          // No previous movie, start today
          startDate = new Date();
          startDate.setHours(0, 0, 0, 0);
        }
        
        // Get next suggestion
        const nextSuggestionDoc = await getNextSuggestionDoc(clubId);
        if (!nextSuggestionDoc) {
          logVerbose("No suggestions available to rotate to.");
          return { 
            success: true, 
            message: "Active movie archived, but no suggestions available for new movie." 
          };
        }
        
        const suggestionData = nextSuggestionDoc.data() as SuggestionData;
        
        // Calculate end date based on club settings
        const endDate = new Date(startDate);
        endDate.setDate(endDate.getDate() + (clubData.timeInterval * 7));
        endDate.setHours(23, 59, 59, 999);  // Set to 11:59:59 PM
        
        // Create new movie document
        const movieData: MovieData = {
          ...suggestionData,
          likes: 0,
          dislikes: 0,
          numCollected: 0,
          numComments: 0,
          imdbId: suggestionData.imdbId,
          status: 'active',
          startDate: Timestamp.fromDate(startDate),
          endDate: Timestamp.fromDate(endDate),
          collectedBy: [],
          movieClubId: clubId,
          likedBy: [],
          dislikedBy: []
        };
        
        // Add the new movie and delete the suggestion
        const movieCollectionRef = getMovieRef(clubId);
        const newMovieRef = movieCollectionRef.doc();
        transaction.set(newMovieRef, movieData);
        transaction.delete(nextSuggestionDoc.ref);
        
        // Update club's movie end date
        transaction.update(clubDocRef, { movieEndDate: Timestamp.fromDate(endDate) });
        
        // Return success with needed data for notifications
        return { 
          success: true, 
          newMovieId: newMovieRef.id,
          movieData: movieData,
          clubData: clubData,
          suggestionData: suggestionData
        };
      }).then(async (result) => {
        // Send notifications if a new movie was created
        if (result.newMovieId && result.suggestionData) {
          await notifyMembersAboutNewMovie(
            clubId, 
            result.clubData.name, 
            result.suggestionData,
            result.newMovieId
          );
        }
        return { success: true };
      });
    } catch (error) {
      console.error('Error rotating movie:', error);
      handleCatchHttpsError('Error rotating movie:', error);
    }
  }
);

// Helper function to notify members about a new movie
async function notifyMembersAboutNewMovie(
  clubId: string, 
  clubName: string, 
  suggestionData: SuggestionData,
  movieId: string
) {
  try {
    // Get all club members
    const membersSnapshot = await firebaseAdmin
      .firestore()
      .collection(`movieclubs/${clubId}/members`)
      .get();
    
    if (membersSnapshot.empty) {
      console.log("No members to notify about new movie");
      return;
    }
    
    const memberIds = membersSnapshot.docs.map(doc => doc.id);
    
    // Get movie details if possible
    let movieTitle = "a new movie";
    if (suggestionData.imdbId) {
      try {
        // Import dynamically to avoid circular dependencies
        const { getMovieDetails } = require("../../notifications/movieHelpers");
        const movieDetails = await getMovieDetails(suggestionData.imdbId);
        if (movieDetails && movieDetails.title) {
          movieTitle = `"${movieDetails.title}"`;
        }
      } catch (error) {
        console.error("Failed to fetch movie details:", error);
      }
    }
    
    // Prepare notification message
    const notificationMessage = `It's time to watch ${movieTitle} in ${clubName}`;
    
    // Process each member
    const notificationPromises = memberIds.map(async (memberId) => {
      // Get user data for FCM token
      const userDoc = await firebaseAdmin.firestore().doc(`users/${memberId}`).get();
      if (!userDoc.exists) return null;
      
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;
      
      // Send push notification if token exists
      if (fcmToken) {
        const payload = {
          token: fcmToken,
          notification: {
            title: `New Movie in ${clubName}`,
            body: notificationMessage,
          },
          data: {
            type: NotificationType.ROTATED,
            clubName: clubName,
            clubId: clubId,
            imdbId: suggestionData.imdbId,
            movieId: movieId
          },
        };
        
        try {
          await firebaseAdmin.messaging().send(payload);
          console.log(`Movie rotation notification sent to ${memberId}`);
        } catch (error) {
          console.error(`Failed to send movie rotation notification to ${memberId}:`, error);
        }
      }
      
      // Add notification document to user's notifications collection
      try {
        await firebaseAdmin
          .firestore()
          .collection(`users/${memberId}/notifications`)
          .add({
            clubName: clubName,
            clubId: clubId,
            userName: suggestionData.userName || "The club",
            userId: suggestionData.userId,
            othersCount: null,
            message: notificationMessage,
            createdAt: new Date(),
            type: NotificationType.ROTATED,
            imdbId: suggestionData.imdbId,
            movieId: movieId
          });
        
        return { success: true, userId: memberId };
      } catch (error) {
        console.error(`Failed to write movie rotation notification for ${memberId}:`, error);
        return null;
      }
    });
    
    await Promise.all(notificationPromises);
    console.log(`Processed movie rotation notifications for club ${clubId}`);
    
  } catch (error) {
    console.error("Failed to notify members about new movie:", error);
  }
}

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
