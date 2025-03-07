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
import { getActiveMovieDoc, getMovieRef } from "./movieHelpers";
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

      // First check if there's already a rotation in progress by looking for any recent archived movies
      // that might have been created in the last hour
      const recentArchiveCheck = await firebaseAdmin
        .firestore()
        .collection(`movieclubs/${clubId}/movies`)
        .where("status", "==", "archived")
        .orderBy("endDate", "desc")
        .limit(1)
        .get();

      if (!recentArchiveCheck.empty) {
        const recentArchive = recentArchiveCheck.docs[0].data() as MovieData;
        const archiveTime = recentArchive.endDate instanceof Date 
          ? recentArchive.endDate 
          : recentArchive.endDate.toDate();
        
        // If there's a recently archived movie (archived in the last hour), prevent duplicate rotation
        const ONE_HOUR_MS = 3600000;
        if (new Date().getTime() - archiveTime.getTime() < ONE_HOUR_MS) {
          logVerbose(`Rotation already happened recently (${archiveTime}). Preventing duplicate rotation.`);
          throw new functions.https.HttpsError(
            'failed-precondition',
            'A movie rotation has already occurred recently. Please try again later.'
          );
        }
      }

      const activeMovieDoc = await getActiveMovieDoc(clubId);

      if (activeMovieDoc) {
        const activeMovie = activeMovieDoc.data() as MovieData;

        // Convert endDate to a JavaScript Date for comparison
        const endDateAsDate = activeMovie.endDate instanceof Date 
          ? activeMovie.endDate 
          : activeMovie.endDate.toDate();

        if (new Date() < endDateAsDate) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'The current movie\'s watch period has not ended.'
          );
        }

        // Add a grace period check to prevent movies from being rotated too quickly
        // Only allow rotation if movie has been active for at least 1 hour
        const now = new Date();
        const startDateAsDate = activeMovie.startDate instanceof Date 
          ? activeMovie.startDate 
          : activeMovie.startDate.toDate();
        
        const ONE_HOUR_MS = 3600000;
        if (now.getTime() - startDateAsDate.getTime() < ONE_HOUR_MS) {
          logVerbose(`Not rotating movie as it was created less than 1 hour ago (${startDateAsDate})`);
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Cannot rotate a movie that was just activated. Please try again later.'
          );
        }

        // Mark the current movie as 'archived' AND update its endDate to 11:59 PM on its end date
        // This ensures the end date is set to a consistent time (end of day)
        const endDateObj = activeMovie.endDate instanceof Date 
          ? activeMovie.endDate 
          : activeMovie.endDate.toDate();
          
        // Set the time to 11:59:59 PM
        const formattedEndDate = new Date(endDateObj);
        formattedEndDate.setHours(23, 59, 59, 999);
        
        // Convert to Firestore Timestamp before updating
        const firestoreEndDate = Timestamp.fromDate(formattedEndDate);
        
        await activeMovieDoc.ref.update({ 
          status: 'archived',
          endDate: firestoreEndDate  // Use the formatted end date with time set to 11:59:59 PM
        });
        
        // Wait a moment to ensure the update completes before proceeding
        await new Promise(resolve => setTimeout(resolve, 1000));
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

      // Delete the suggestion
      await nextSuggestionDoc.ref.delete();

      // Set start date to 12:00 AM on the day after the previous movie ends
      let startDate;
      if (activeMovieDoc) {
        // If there was an active movie, set the start date to the day after it ends
        const activeMovie = activeMovieDoc.data() as MovieData;
        const previousEndDate = activeMovie.endDate instanceof Date
          ? activeMovie.endDate
          : activeMovie.endDate.toDate();
        
        // Create a new date for the day after the previous end date
        startDate = new Date(previousEndDate);
        startDate.setDate(startDate.getDate() + 1);
        startDate.setHours(0, 0, 0, 0);  // Set to 12:00:00 AM
      } else {
        // If there was no active movie, start today at 12:00 AM
        startDate = new Date();
        startDate.setHours(0, 0, 0, 0);  // Set to 12:00:00 AM
      }

      // Calculate end date based on timeInterval
      const endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + (clubData.timeInterval * 7));
      // Set end date to 11:59:59 PM on the end day
      endDate.setHours(23, 59, 59, 999);

      // Convert to Firestore Timestamps for storage
      const firestoreStartDate = Timestamp.fromDate(startDate);
      const firestoreEndDate = Timestamp.fromDate(endDate);

      const movieData: MovieData = {
        ...suggestionData,
        likes: 0,
        dislikes: 0,
        numCollected: 0,
        numComments: 0,
        imdbId: suggestionData.imdbId,
        status: 'active',
        startDate: firestoreStartDate,
        endDate: firestoreEndDate,
        collectedBy: [],
        movieClubId: clubId,
        likedBy: [],
        dislikedBy: []
      };

      // Add the new movie as 'active'
      const movieCollectionRef = getMovieRef(clubId);
      const newMovieRef = await movieCollectionRef.add(movieData);
      const newMovieId = newMovieRef.id;

      // Update movieEndDate in the movieClub document
      await clubDocRef.update({ movieEndDate: firestoreEndDate });

      // Send notifications to all club members about the new movie
      await notifyMembersAboutNewMovie(clubId, clubData.name, suggestionData, newMovieId);

      logVerbose('Movie rotated successfully!');
      return { success: true };
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
    
    // Get movie details - you might want to fetch more details from an external API
    // For now we'll use a generic message
    const movieTitle = "a new movie"; // Could be fetched using suggestionData.imdbId
    
    // Prepare notification message
    const notificationMessage = `New movie to watch: ${movieTitle}`;
    
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
            type: 'rotated',
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
            message: notificationMessage,
            createdAt: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
            type: "rotated",
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