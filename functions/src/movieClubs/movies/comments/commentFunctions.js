const functions = require("firebase-functions");
const { db } = require("firestore");
const { verifyRequiredFields } = require("utilities")

exports.postComment = functions.https.onCall(async (data, context) => {
    const requiredFields = ["movieClubId", "movieId", "text", "userID", "username"]
    verifyRequiredFields(data, requiredFields)

    try {
        // Reference to the specific movie"s comments collection
        const commentsRef = db
            .collection("movieclubs")
            .doc(data.movieClubId)
            .collection("movies")
            .doc(data.movieId)
            .collection("comments");

        const commentData = {
            userID: data.userID,
            username: data.username,
            text: data.text
        }

        // Add the comment to the "comments" sub-collection
        await commentsRef.add(commentData);

        console.log("Comment posted successfully!");
    } catch (error) {
        console.error("Error posting comment:", error);
    }
})
