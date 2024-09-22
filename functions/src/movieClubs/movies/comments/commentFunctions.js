const functions = require("firebase-functions");
const { db, admin } = require("firestore");
const { handleCatchHttpsError, logVerbose, verifyRequiredFields } = require("utilities");

exports.postComment = functions.https.onCall(async (data, context) => {
  try {
    const requiredFields = ["movieClubId", "movieId", "text", "userId", "username"]
    verifyRequiredFields(data, requiredFields)

    const commentsRef = db
      .collection("movieclubs")
      .doc(data.movieClubId)
      .collection("movies")
      .doc(data.movieId)
      .collection("comments");

    const commentData = {
      userId: data.userId,
      username: data.username,
      text: data.text,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    }

    await commentsRef.add(commentData);

    logVerbose("Comment posted successfully!");
  } catch (error) {
    handleCatchHttpsError("Error posting comment:", error)
  }
})
