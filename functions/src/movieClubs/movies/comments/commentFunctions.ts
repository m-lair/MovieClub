import * as functions from "firebase-functions";
import { firestore } from "firestore";
import { handleCatchHttpsError, logVerbose, verifyRequiredFields } from "helpers";
import { DeleteCommentData, PostCommentData } from "./commentTypes";
import { CallableRequest } from "firebase-functions/https";
import { COMMENTS, MOVIE_CLUBS, MOVIES } from "src/utilities/collectionNames";

exports.postComment = functions.https.onCall(async (request: CallableRequest<PostCommentData>) => {
  try {
    const requiredFields = ["movieClubId", "movieId", "text", "userId", "username"]
    verifyRequiredFields(request.data, requiredFields)

    const commentsRef = firestore
      .collection(MOVIE_CLUBS)
      .doc(request.data.movieClubId)
      .collection(MOVIES)
      .doc(request.data.movieId)
      .collection(COMMENTS);

    const commentData = {
      userId: request.data.userId,
      username: request.data.username,
      text: request.data.text,
      likes: 0,
      image: request.data.image || "",
      createdAt: Date.now()
    }

    const commentDoc = await commentsRef.add(commentData);

    logVerbose("Comment posted successfully!");

    return commentDoc.id;
  } catch (error) {
    handleCatchHttpsError("Error posting comment:", error)
  }
});

exports.deleteComment = functions.https.onCall(async (request: CallableRequest<DeleteCommentData>) => {
  try {
    const requiredFields = ["id", "movieClubId", "movieId"];
    verifyRequiredFields(request.data, requiredFields);

    const commentRef = firestore
      .collection(MOVIE_CLUBS)
      .doc(request.data.movieClubId)
      .collection(MOVIES)
      .doc(request.data.movieId)
      .collection(COMMENTS)
      .doc(request.data.id);

    // Delete the comment
    await commentRef.delete();

    logVerbose("Comment deleted successfully!");
  } catch (error) {
    handleCatchHttpsError("Error deleting comment:", error);
  };
});
