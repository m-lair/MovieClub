import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { SuggestionData } from "../movieClubs/suggestions/suggestionTypes";
import { getMovieClub } from "../movieClubs/movieClubHelpers";
import { UserData } from "src/users/userTypes";
import { getUser } from "src/users/userHelpers";

export const notifyClubMembersOnNewSuggestion = onDocumentCreated(
  "movieclubs/{clubId}/suggestions/{suggestionId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No document data");
      return null;
    }

    const { clubId } = event.params;
    const suggestionData = snapshot.data() as SuggestionData;
    const suggesterUserId = suggestionData.userId;
    
    try {
      // Get club data
      const clubSnapshot = await getMovieClub(clubId);
      if (!clubSnapshot.exists) {
        console.log(`Club ${clubId} not found`);
        return null;
      }
      
      const clubName = clubSnapshot.data()?.name || "Unnamed Club";
      
      // Get all club members
      const membersSnapshot = await admin
        .firestore()
        .collection(`movieclubs/${clubId}/members`)
        .get();
      
      // Filter out the user who made the suggestion
      const memberIds = membersSnapshot.docs
        .map(doc => doc.id)
        .filter(userId => userId !== suggesterUserId);
      
      if (memberIds.length === 0) {
        console.log("No other members to notify");
        return null;
      }
      
      // Get movie details from IMDB ID if needed
      // For now, we'll just use a generic message
      const movieTitle = "a new movie"; // You could fetch the actual title if needed
      
      // Get user data for all members in parallel
      const userPromises = memberIds.map((userId) => getUser(userId));
      const userSnapshots = await Promise.all(userPromises);
      
      // Prepare and send notifications
      const notifications = userSnapshots.map(async (userSnap) => {
        if (!userSnap.exists) return null;
        
        const userData = userSnap.data() as UserData;
        if (!userData) return null;
        
        // Check FCM token
        const fcmToken = userData.fcmToken;
        
        // Prepare notification message
        const notificationMessage = `${suggestionData.userName} suggested ${movieTitle}`;
        
        // Send FCM push notification if token exists
        if (fcmToken) {
          const payload = {
            token: fcmToken,
            notification: {
              title: `New Movie Suggestion in ${clubName}`,
              body: notificationMessage,
            },
            data: {
              type: 'suggested',
              clubName: clubName,
              userName: suggestionData.userName,
              clubId: clubId,
              imdbId: suggestionData.imdbId,
            },
          };
          
          try {
            await admin.messaging().send(payload);
            console.log(`Suggestion notification sent to ${userSnap.id}`);
          } catch (error) {
            console.error(`Failed to send suggestion notification to ${userSnap.id}:`, error);
          }
        }
        
        // Add notification document to user's notifications collection
        try {
          await admin
            .firestore()
            .collection(`users/${userSnap.id}/notifications`)
            .add({
              clubName: clubName,
              clubId: clubId,
              userName: suggestionData.userName,
              userId: suggestionData.userId,
              othersCount: null,
              message: `${suggestionData.userName} suggested a movie in ${clubName}`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              type: "suggested",
              imdbId: suggestionData.imdbId,
            });
          
          return { success: true, userId: userSnap.id };
        } catch (error) {
          console.error(`Failed to write suggestion notification for ${userSnap.id}:`, error);
          return null;
        }
      });
      
      // Wait for all notifications to complete
      const results = await Promise.all(notifications);
      console.log(`Processed ${results.filter(Boolean).length} suggestion notifications`);
      
      return { success: true, notifiedUsers: results.filter(Boolean) };
    } catch (error) {
      console.error("Suggestion notification workflow failed:", error);
      return null;
    }
  }
);