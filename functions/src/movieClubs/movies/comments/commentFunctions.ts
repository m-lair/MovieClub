const functions = require("firebase-functions");
const { firestore, firebaseAdmin } = require("firestore");
const { handleCatchHttpsError, logVerbose, verifyRequiredFields } = require("utilities");

export const postComment = functions.https.onCall(async (data, context) => {
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
      createdAt: firebaseAdmin.firestore.FieldValue.serverTimestamp()
    }

    const commentDoc = await commentsRef.add(commentData);

    logVerbose("Comment posted successfully!");

    return commentDoc.id;
  } catch (error) {
    handleCatchHttpsError("Error posting comment:", error)
  }
});

export const deleteComment = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["commentId", "movieClubId", "movieId"];
    verifyRequiredFields(data, requiredFields);

    const commentRef = firestore
      .collection("movieclubs")
      .doc(data.movieClubId)
      .collection("movies")
      .doc(data.movieId)
      .collection("comments")
      .doc(data.commentId);

    // Delete the comment
    await commentRef.delete();

    logVerbose("Comment deleted successfully!");
  } catch (error) {
    handleCatchHttpsError("Error deleting comment:", error);
  };
});
