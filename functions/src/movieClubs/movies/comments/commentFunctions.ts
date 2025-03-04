import * as functions from "firebase-functions";
import { firebaseAdmin } from "firestore";
import {
  handleCatchHttpsError,
  logVerbose,
  throwHttpsError,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import {
  DeleteCommentData,
  PostCommentData,
  LikeCommentData,
  UnlikeCommentData,
  AnonymizeCommentData,
  ReportCommentData
} from "./commentTypes";
import { CallableRequest } from "firebase-functions/https";
import { verifyMembership } from "src/users/memberships/membershipHelpers";
import { getCommentsDocRef, getCommentsRef } from "./commentHelpers";

exports.postComment = functions.https.onCall(
  async (request: CallableRequest<PostCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ["clubId", "movieId", "text", "userName"];
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, data.clubId);

      const commentsRef = getCommentsRef(data.clubId, data.movieId)

      const commentData = {
        userId: uid,
        text: data.text,
        userName: data.userName,
        createdAt: new Date(),
        likedBy: [],
        image: data.image || "null",
        parentId: data.parentId || null,
        likes: 0
      };

      const docRef = await commentsRef.add(commentData);
      return docRef.id;
    } catch (error) {
      handleCatchHttpsError("Error posting comment:", error);
    }
  },
);

exports.likeComment = functions.https.onCall(
  async (request: CallableRequest<LikeCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ['clubId', 'movieId', 'commentId'];
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, data.clubId);

      const commentRef = getCommentsDocRef(data.clubId, data.movieId, data.commentId)

      await commentRef.update({
        likedBy: firebaseAdmin.firestore.FieldValue.arrayUnion(uid),
        likes: firebaseAdmin.firestore.FieldValue.increment(1),
      });

      return { success: true };
    } catch (error) {
      handleCatchHttpsError('Error liking comment:', error);
    }
  },
);

exports.unlikeComment = functions.https.onCall(
  async (request: CallableRequest<UnlikeCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ['clubId', 'movieId', 'commentId'];
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, data.clubId);

      const commentRef = getCommentsDocRef(data.clubId, data.movieId, data.commentId)

      await commentRef.update({
        likedBy: firebaseAdmin.firestore.FieldValue.arrayRemove(uid),
        likes: firebaseAdmin.firestore.FieldValue.increment(-1),
      });

      return { success: true };
    } catch (error) {
      handleCatchHttpsError('Error unliking comment:', error);
    }
  },
);

exports.anonymizeComment = functions.https.onCall(
  async (request: CallableRequest<AnonymizeCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ['clubId', 'movieId', 'commentId'];
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, data.clubId);

      const commentRef = getCommentsDocRef(data.clubId, data.movieId, data.commentId)
      const commentSnap = await commentRef.get();
      const commentData = commentSnap.data();

      if (commentData === undefined) {
        throwHttpsError(
          "not-found",
          "Comment not found.",
        );
      }
      
      if (commentData!.userId !== uid) {
        throwHttpsError(
          "permission-denied",
          "You cannot anonymize a comment that you don't own.",
        );
      }
      
      // Check if the comment is already anonymized
      if (commentData!.userId === "anonymous-user") {
        return { 
          success: true,
          message: "Comment was already anonymized.",
          alreadyAnonymized: true
        };
      }

      // Anonymize the comment instead of deleting it
      // Remove all user-identifying information
      const updateData = {
        userName: "Deleted User",
        text: "[This comment has been deleted by the user]",
        image: null,
        // Use a placeholder userId that can't be traced back to the original user
        // but still allows the comment to exist in the tree structure
        userId: "anonymous-user",
        // Keep the comment in the tree structure but remove personal data
        likedBy: [], // Remove all likes
        likes: 0     // Reset likes count
      };
      
      await commentRef.update(updateData);
      
      logVerbose("Comment anonymized successfully!");
      return { 
        success: true,
        message: "Comment anonymized successfully.",
        alreadyAnonymized: false
      };
    } catch (error) {
      handleCatchHttpsError("Error anonymizing comment:", error);
    }
  },
);

exports.reportComment = functions.https.onCall(
  async (request: CallableRequest<ReportCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ['clubId', 'movieId', 'commentId', 'reason'];
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, data.clubId);

      // Get the comment data
      const commentRef = getCommentsDocRef(data.clubId, data.movieId, data.commentId);
      const commentSnap = await commentRef.get();
      
      if (!commentSnap.exists) {
        throwHttpsError("not-found", "Comment not found");
      }
      
      const commentData = commentSnap.data();
      
      // Don't allow reporting your own comments
      if (commentData && commentData.userId === uid) {
        throwHttpsError(
          "invalid-argument", 
          "You cannot report your own comment"
        );
      }
      
      // Check if this user has already reported this comment
      const existingReportQuery = await firebaseAdmin.firestore()
        .collection('reports')
        .where('commentId', '==', data.commentId)
        .where('reportedBy', '==', uid)
        .limit(1)
        .get();
      
      if (!existingReportQuery.empty) {
        return {
          success: true,
          message: "You have already reported this comment.",
          alreadyReported: true
        };
      }
      
      // Create a report document
      const reportsRef = firebaseAdmin.firestore().collection('reports');
      const reportData = {
        commentId: data.commentId,
        clubId: data.clubId,
        movieId: data.movieId,
        reportedBy: uid,
        reason: data.reason,
        createdAt: new Date(),
        status: 'pending'
      };
      
      await reportsRef.add(reportData);
      
      logVerbose("Comment reported successfully!");
      return { 
        success: true,
        message: "Comment reported successfully.",
        alreadyReported: false
      };
    } catch (error) {
      handleCatchHttpsError("Error reporting comment:", error);
    }
  },
);

exports.deleteComment = functions.https.onCall(
  async (request: CallableRequest<DeleteCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ["id", "clubId", "movieId"];
      verifyRequiredFields(request.data, requiredFields);
      await verifyMembership(uid, data.clubId);

      // Forward to anonymizeComment for backward compatibility
      const commentRef = getCommentsDocRef(data.clubId, data.movieId, data.id);
      const commentSnap = await commentRef.get();
      const commentData = commentSnap.data();

      if (commentData === undefined || commentData.userId !== uid) {
        throwHttpsError(
          "permission-denied",
          "You cannot delete a comment that you don't own.",
        );
      } else {
        // Use the anonymize logic instead of deleting
        // Anonymize the comment instead of deleting it
        // Remove all user-identifying information
        const updateData = {
          userName: "Deleted User",
          text: "[This comment has been deleted by the user]",
          image: null,
          // Use a placeholder userId that can't be traced back to the original user
          // but still allows the comment to exist in the tree structure
          userId: "anonymous-user",
          // Keep the comment in the tree structure but remove personal data
          likedBy: [], // Remove all likes
          likes: 0     // Reset likes count
        };
        
        await commentRef.update(updateData);
        
        logVerbose("Comment anonymized via deprecated deleteComment function");
        return { 
          success: true,
          message: "Comment anonymized successfully.",
          deprecated: true
        };
      }
    } catch (error) {
      handleCatchHttpsError("Error in deprecated deleteComment function:", error);
    }
  },
);
