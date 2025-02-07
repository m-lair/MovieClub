import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { CommentData } from "../movieClubs/movies/comments/commentTypes";
import { UserData } from "src/users/userTypes";

export const notifyClubMembersOnComment = onDocumentCreated(
  "movieclubs/{clubId}/movies/{movieId}/comments/{commentId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No document data");
      return null;
    }

    const { clubId } = event.params;
    const commentData = snapshot.data() as CommentData;
    const commentAuthorId = commentData.userId;

    try {
      // 1. Get club members
      const membersSnapshot = await admin
        .firestore()
        .collection(`movieclubs/${clubId}/members`)
        .get();

      // 2. Filter out comment author and get member IDs
      const memberIds = membersSnapshot.docs
        .map((doc) => doc.id)
        .filter((userId) => userId !== commentAuthorId);

      // 3. Get user data for all members in parallel
      const userPromises = memberIds.map((userId) =>
        admin.firestore().doc(`users/${userId}`).get()
      );
      const userSnapshots = await Promise.all(userPromises);

      // Get club info
      const clubSnapshot = await admin.firestore().doc(`movieclubs/${clubId}`).get();
      const clubName = clubSnapshot.data()?.name || "Unnamed Club";

      // 4. Prepare and send notifications
      const notifications = userSnapshots.map(async (userSnap) => {
        const userData = userSnap.data() as UserData | undefined;
        if (!userData) return null;

        // Check FCM token
        const fcmToken = userData.fcmToken;
        if (!fcmToken) return null;

        // Prepare payload for push
        const payload = {
          token: fcmToken,
          notification: {
            title: `New Comments in ${clubName}!`,
            body: `${commentData.userName} commented in ${clubName}!`,
          },
        };

        // Send FCM message
        try {
          await admin.messaging().send(payload);
          console.log(`Notification sent to ${userSnap.id}`);

          // Add a document to user/{userId}/notifications
          await admin
            .firestore()
            .collection(`users/${userSnap.id}/notifications`)
            .add({
              clubName: clubName,
              userName: commentData.userName,
              othersCount: null, // or set to 0 or actual count if needed
              message: `${commentData.userName} left a comment`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              type: "commented", // maps to your NotificationType
            });

          return { success: true, userId: userSnap.id };
        } catch (error) {
          console.error(`Failed to notify ${userSnap.id}:`, error);
          return null;
        }
      });

      // Wait for all notifications to complete
      const results = await Promise.all(notifications);
      console.log(`Processed ${results.length} notifications`);
      return { success: true, notifiedUsers: results.filter(Boolean) };
    } catch (error) {
      console.error("Notification workflow failed:", error);
      return null;
    }
  }
);