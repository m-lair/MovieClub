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
  UnlikeCommentData
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


exports.deleteComment = functions.https.onCall(
  async (request: CallableRequest<DeleteCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ["id", "clubId", "movieId"];
      verifyRequiredFields(request.data, requiredFields);

      const commentRef = getCommentsDocRef(data.clubId, data.movieId, data.id)
      const commentSnap = await commentRef.get();
      const commentData = commentSnap.data();

      if (commentData === undefined || commentData.userId !== uid) {
        throwHttpsError(
          "permission-denied",
          "You cannot delete a comment that you don't own.",
        );
      } else {
        await commentRef.delete();
        logVerbose("Comment deleted successfully!");
      }
    } catch (error) {
      handleCatchHttpsError("Error deleting comment:", error);
    }
  },
);
