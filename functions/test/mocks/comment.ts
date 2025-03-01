import { logError, logVerbose } from "helpers";
import { getCommentsDocRef } from "src/movieClubs/movies/comments/commentHelpers";

export interface CommentMock {
  id: string;
  image: string;
  text: string;
  userId: string;
  username: string;
  likedBy: Array<string>;
  likes: number;
  createdAt: number;
}

type CommentMockParams = Partial<CommentMock> & {
  movieClubId?: string;
  movieId?: string;
};

export async function populateCommentData(
  params: CommentMockParams = {},
): Promise<CommentMock> {
  logVerbose("Populating comment data...");
  const movieClubId = params.movieClubId || "test-club-id";
  const movieId = params.movieId || "test-movie-id";
  const id = params.id || "test-comment-id";

  const commentData: CommentMock = {
    id: id,
    image: params.image || "Test image",
    text: params.text || "Test text",
    userId: params.id || "test-user-id",
    username: params.username || "Test User",
    likedBy: params.likedBy || [],
    likes: params.likes || 0,
    createdAt: Date.now(),
  };

  const commentsRef = getCommentsDocRef(movieClubId, movieId, id)
  
  try {
    await commentsRef.set(commentData);
    logVerbose("comment data set");
  } catch (error) {
    logError("Error setting comment data:", error);
  }

  return commentData;
}
