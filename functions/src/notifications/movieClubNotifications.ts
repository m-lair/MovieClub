import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { getMovieClub } from "../movieClubs/movieClubHelpers";
import { MovieClubData } from "../movieClubs/movieClubTypes";
import { UserData } from "src/users/userTypes";
import { getUser } from "src/users/userHelpers";

export const notifyClubOwnerOnNewMember = onDocumentCreated(
  "movieclubs/{clubId}/members/{userId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No document data");
      return null;
    }

    const { clubId, userId } = event.params;
    
    try {
      // Get club data to find the owner
      const clubSnapshot = await getMovieClub(clubId);
      if (!clubSnapshot.exists) {
        console.log(`Club ${clubId} not found`);
        return null;
      }
      
      const clubData = clubSnapshot.data() as MovieClubData;
      const clubName = clubData.name || "Unnamed Club";
      const ownerId = clubData.ownerId;
      
      // Skip if the new member is the owner
      if (userId === ownerId) {
        console.log("Owner joined their own club. Skipping notification.");
        return null;
      }
      
      // Get the new member's data
      const newMemberSnapshot = await getUser(userId);
      if (!newMemberSnapshot.exists) {
        console.log(`User ${userId} not found`);
        return null;
      }
      
      const newMemberData = newMemberSnapshot.data() as UserData;
      const memberName = newMemberData.name || "A new user";
      
      // Get the owner's data for FCM token
      const ownerSnapshot = await getUser(ownerId);
      if (!ownerSnapshot.exists) {
        console.log(`Owner ${ownerId} not found`);
        return null;
      }
      
      const ownerData = ownerSnapshot.data() as UserData;
      const ownerFcmToken = ownerData.fcmToken;
      
      // Send push notification if owner has FCM token
      if (ownerFcmToken) {
        const payload = {
          token: ownerFcmToken,
          notification: {
            title: `New Member in ${clubName}`,
            body: `${memberName} joined your club!`,
          },
          data: {
            type: 'joined',
            clubName: clubName,
            userName: memberName,
            clubId: clubId,
            userId: userId
          },
        };
        
        try {
          const messageId = await admin.messaging().send(payload);
          console.log(`Join notification sent to owner ${ownerId} (msg id: ${messageId})`);
        } catch (error) {
          console.error(`Failed to send join notification to ${ownerId}:`, error);
        }
      }
      
      // Add notification document to owner's notifications collection
      try {
        await admin
          .firestore()
          .collection(`users/${ownerId}/notifications`)
          .add({
            clubName: clubName,
            clubId: clubId,
            userName: memberName,
            userId: userId,
            othersCount: null,
            message: `${memberName} joined your club`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            type: "joined",
          });
        console.log(`Join notification document written for owner ${ownerId}`);
      } catch (error) {
        console.error("Failed to write join notification document:", error);
      }
      
      return { success: true };
    } catch (error) {
      console.error("Club join notification workflow failed:", error);
      return null;
    }
  }
);