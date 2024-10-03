import * as functions from "firebase-functions";
import { firestore, firebaseAdmin } from "firestore";
import { handleCatchHttpsError, logVerbose, verifyRequiredFields } from "helpers";
import { DeleteCommentData, PostCommentData } from "./commentTypes";

exports.postComment = functions.https.onCall(async (data: PostCommentData, context) => {
  try {
    const requiredFields = ["movieClubId", "movieId", "text", "userId", "username"]
    verifyRequiredFields(data, requiredFields)

    const commentsRef = firestore
      .collection("movieclubs")
      .doc(data.movieClubId)
      .collection("movies")
      .doc(data.movieId)
      .collection("comments");

    const commentData = {
      userId: data.userId,
      username: data.username,
      text: data.text,
      likes: 0,
      image: data.image || "",
      createdAt: Date.now()
    }

    const commentDoc = await commentsRef.add(commentData);

    logVerbose("Comment posted successfully!");

    return commentDoc.id;
  } catch (error) {
    handleCatchHttpsError("Error posting comment:", error)
  }
});

exports.deleteComment = functions.https.onCall(async (data: DeleteCommentData, context) => {
  try {
    const requiredFields = ["id", "movieClubId", "movieId"];
    verifyRequiredFields(data, requiredFields);

    const commentRef = firestore
      .collection("movieclubs")
      .doc(data.movieClubId)
      .collection("movies")
      .doc(data.movieId)
      .collection("comments")
      .doc(data.id);

    // Delete the comment
    await commentRef.delete();

    logVerbose("Comment deleted successfully!");
  } catch (error) {
    handleCatchHttpsError("Error deleting comment:", error);
  };
});
