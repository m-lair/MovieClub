import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { CommentData } from "../movieClubs/movies/comments/commentTypes";
import { getMovieClub } from "../movieClubs/movieClubHelpers";
import { UserData } from "src/users/userTypes";
import { getUser } from "src/users/userHelpers";

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
        getUser(userId)
      );
      const userSnapshots = await Promise.all(userPromises);

      // Get club info
      const clubSnapshot = await getMovieClub(clubId);
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
          data: {
            type: 'commented',
            clubName: clubName,
            userName: commentData.userName,
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

export const notifyCommentLiked = onDocumentUpdated(
  "movieclubs/{clubId}/movies/{movieId}/comments/{commentId}",
  async (event) => {
    // Get the comment data before and after the update
    const beforeData = event.data?.before.data() as CommentData;
    const afterData = event.data?.after.data() as CommentData;
    if (!beforeData || !afterData) {
      console.log("Missing comment data");
      return null;
    }

    // Compare likedBy arrays (assuming likedBy is a string[] field)
    const beforeLikes: string[] = beforeData.likedBy || [];
    const afterLikes: string[] = afterData.likedBy || [];
    const newLikes = afterLikes.filter((userId) => !beforeLikes.includes(userId));
    if (newLikes.length === 0) {
      console.log("No new likes.");
      return null;
    }

    // Get the comment author (assume comment doc holds the original author's id)
    const commentAuthorId = afterData.userId;
    if (!commentAuthorId) {
      console.log("Comment does not have an author.");
      return null;
    }

    // Extract path params and get club info
    const { clubId } = event.params;
    const clubSnapshot = await admin.firestore().doc(`movieclubs/${clubId}`).get();
    const clubName = clubSnapshot.data()?.name || "Unnamed Club";

    // Get comment author's user data (to retrieve fcmToken)
    const commentAuthorDoc = await admin.firestore().doc(`users/${commentAuthorId}`).get();
    if (!commentAuthorDoc.exists) {
      console.log("Original comment author not found");
      return null;
    }
    const commentAuthorData = commentAuthorDoc.data() as UserData;
    const authorFcmToken = commentAuthorData.fcmToken;

    // Process each new like
    await Promise.all(
      newLikes.map(async (likerId) => {
        // Skip if the comment author liked their own comment
        if (likerId === commentAuthorId) {
          console.log("User liked their own comment. Skipping notification for:", likerId);
          return;
        }

        // Look up the liker’s user data to get their name
        const likerDoc = await admin.firestore().doc(`users/${likerId}`).get();
        if (!likerDoc.exists) {
          console.log("Liker user not found for:", likerId);
          return;
        }
        const likerData = likerDoc.data() as UserData;
        const likerName = likerData.name || "Someone";

        // Prepare the FCM payload
        if (authorFcmToken) {
          const payload = {
            token: authorFcmToken,
            notification: {
              title: "Your comment was liked!",
              body: `${likerName} liked your comment in ${clubName}!`,
            },
            data: {
              type: "liked",
              clubName: clubName,
              userName: likerName,
            },
          };

          try {
            const messageId = await admin.messaging().send(payload);
            console.log(
              `Like notification sent to ${commentAuthorId} for like from ${likerId} (msg id: ${messageId})`
            );
          } catch (error) {
            console.error(`Failed to send like notification to ${commentAuthorId}:`, error);
          }
        }

        // Write a notification document to the comment author's notifications collection
        try {
          await admin
            .firestore()
            .collection(`users/${commentAuthorId}/notifications`)
            .add({
              clubName: clubName,
              userName: likerName,
              othersCount: null,
              message: `${likerName} liked your comment`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              type: "liked",
            });
          console.log("Like notification document written for", commentAuthorId);
        } catch (error) {
          console.error("Failed to write like notification document:", error);
        }
      })
    );

    return { success: true };
  }
);


// Function for comment replies
export const notifyCommentReply = onDocumentCreated(
  "movieclubs/{clubId}/movies/{movieId}/comments/{commentId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No comment data");
      return null;
    }

    const { clubId, movieId } = event.params;
    const commentData = snapshot.data() as CommentData;

    // Only process if this comment is a reply (i.e. has a non-null parentId)
    if (!commentData.parentId) {
      console.log("This comment is not a reply. Skipping reply notification.");
      return null;
    }
    const parentId = commentData.parentId;

    // Get the parent comment
    const parentCommentRef = admin
      .firestore()
      .doc(`movieclubs/${clubId}/movies/${movieId}/comments/${parentId}`);
    const parentCommentSnapshot = await parentCommentRef.get();
    if (!parentCommentSnapshot.exists) {
      console.log("Parent comment does not exist");
      return null;
    }
    const parentCommentData = parentCommentSnapshot.data() as CommentData;
    const parentCommentAuthorId = parentCommentData.userId;

    // Optionally, skip if the replier is the same as the original comment's author
    if (parentCommentAuthorId === commentData.userId) {
      console.log("User replied to their own comment. No notification sent.");
      return null;
    }

    // Get club info (for clubName)
    const clubSnapshot = await admin
      .firestore()
      .doc(`movieclubs/${clubId}`)
      .get();
    const clubName = clubSnapshot.data()?.name || "Unnamed Club";

    // Get the original comment author's user data
    const userDoc = await admin.firestore().doc(`users/${parentCommentAuthorId}`).get();
    const userData = userDoc.data() as UserData;
    if (!userData) {
      console.log("Parent comment author not found");
      return null;
    }
    const fcmToken = userData.fcmToken;

    // Prepare and send FCM push (if token exists)
    if (fcmToken) {
      const payload = {
        token: fcmToken,
        notification: {
          title: "New reply to your comment!",
          body: `${commentData.userName} replied to your comment in ${clubName}!`,
        },
        data: {
          type: "replied",
          clubName: clubName,
          userName: commentData.userName,
        },
      };
      try {
        const messageId = await admin.messaging().send(payload);
        console.log(`Reply notification sent to ${parentCommentAuthorId} (msg id: ${messageId})`);
      } catch (error) {
        console.error(`Failed to send reply notification to ${parentCommentAuthorId}:`, error);
      }
    }

    // Write a notification document to the user's notifications collection
    try {
      await admin
        .firestore()
        .collection(`users/${parentCommentAuthorId}/notifications`)
        .add({
          clubName: clubName,
          userName: commentData.userName,
          othersCount: null,
          message: `${commentData.userName} replied to your comment`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          type: "replied",
        });
      console.log("Reply notification document written for", parentCommentAuthorId);
    } catch (error) {
      console.error("Failed to write reply notification document:", error);
    }
    return { success: true };
  }
);
