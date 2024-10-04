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
<<<<<<< HEAD
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
=======

exports.postComment = functions.https.onCall(async (request: CallableRequest<PostCommentData>) => {
  try {
    const requiredFields = ["movieClubId", "movieId", "text", "userId", "username"]
    verifyRequiredFields(request.data, requiredFields)

    const commentsRef = firestore
      .collection("movieclubs")
      .doc(request.data.movieClubId)
      .collection("movies")
      .doc(request.data.movieId)
      .collection("comments");

    const commentData = {
      userId: request.data.userId,
      username: request.data.username,
      text: request.data.text,
      likes: 0,
      image: request.data.image || "",
      createdAt: Date.now()
>>>>>>> 833179b (update to latest firebase-functions version)
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

<<<<<<< HEAD
      const commentRef = firestore
        .collection(MOVIE_CLUBS)
        .doc(data.movieClubId)
        .collection(MOVIES)
        .doc(data.movieId)
        .collection(COMMENTS)
        .doc(data.id);

      const commentSnap = await commentRef.get();
      const commentData = commentSnap.data();
=======
exports.deleteComment = functions.https.onCall(async (request: CallableRequest<DeleteCommentData>) => {
  try {
    const requiredFields = ["id", "movieClubId", "movieId"];
    verifyRequiredFields(request.data, requiredFields);

    const commentRef = firestore
      .collection("movieclubs")
      .doc(request.data.movieClubId)
      .collection("movies")
      .doc(request.data.movieId)
      .collection("comments")
      .doc(request.data.id);
>>>>>>> 833179b (update to latest firebase-functions version)

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
