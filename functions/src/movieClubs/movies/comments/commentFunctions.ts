import * as functions from "firebase-functions";
import { firestore } from "firestore";
import {
  handleCatchHttpsError,
  logVerbose,
  throwHttpsError,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { DeleteCommentData, PostCommentData } from "./commentTypes";
import { CallableRequest } from "firebase-functions/https";
import {
  COMMENTS,
  MEMBERSHIPS,
  MOVIE_CLUBS,
  MOVIES,
  USERS,
} from "src/utilities/collectionNames";

exports.postComment = functions.https.onCall(
  async (request: CallableRequest<PostCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ["movieClubId", "movieId", "text", "username"];
      verifyRequiredFields(data, requiredFields);

      const membershipRef = firestore
        .collection(USERS)
        .doc(uid)
        .collection(MEMBERSHIPS)
        .doc(data.movieClubId);

      const membershipSnap = await membershipRef.get();
      const membershipData = membershipSnap.data();

      if (membershipData === undefined) {
        throwHttpsError(
          "permission-denied",
          "You are not a member of this Movie Club.",
        );
      }

      const commentsRef = firestore
        .collection(MOVIE_CLUBS)
        .doc(data.movieClubId)
        .collection(MOVIES)
        .doc(data.movieId)
        .collection(COMMENTS);

      const commentData = {
        userId: uid,
        username: data.username,
        text: data.text,
        likes: 0,
        image: data.image || "",
        createdAt: Date.now(),
      };

      const commentDoc = await commentsRef.add(commentData);

      logVerbose("Comment posted successfully!");

      return commentDoc.id;
    } catch (error) {
      handleCatchHttpsError("Error posting comment:", error);
    }
  },
);

exports.deleteComment = functions.https.onCall(
  async (request: CallableRequest<DeleteCommentData>) => {
    try {
      const { data, auth } = request;

      const { uid } = verifyAuth(auth);

      const requiredFields = ["id", "movieClubId", "movieId"];
      verifyRequiredFields(request.data, requiredFields);

      const commentRef = firestore
        .collection(MOVIE_CLUBS)
        .doc(data.movieClubId)
        .collection(MOVIES)
        .doc(data.movieId)
        .collection(COMMENTS)
        .doc(data.id);

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
