import { firestore, firebaseAdmin } from "firestore";
import { logError, logVerbose } from "helpers";
import { CommentData, PostCommentData } from "src/movieClubs/movies/comments/commentTypes";

interface CommentMock extends CommentData {
  id: string;
}
interface PostCommentMock extends PostCommentData, CommentMock {
  likes: number;
}

async function populateCommentData(params: PostCommentMock): Promise<CommentMock | undefined> {
  logVerbose('Populating comment data...');
  const movieClubId = params.movieClubId || "test-club-id";
  const movieId = params.movieId || "test-movie-id";
  const id = params.id || 'test-comment-id';

  const commentData: CommentMock = {
    id: id,
    image: params.image || "Test image",
    text: params.text || "Test text",
    userId: params.username || "test-user-id",
    username: params.username || "Test User",
    likes: params.likes || 0,
    createdAt: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
  };

  const commentsRef = firestore.collection("movieclubs").doc(movieClubId).collection('movies').doc(movieId).collection('comments').doc(id)
  try {
    await commentsRef.set(commentData);
    logVerbose('comment data set');

    return commentData
  } catch (error) {
    logError("Error setting comment data:", error);
  }
};

module.exports = { populateCommentData };