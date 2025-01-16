const { logError, logVerbose } = require("helpers");
const { firestore, firebaseAdmin } = require("firestore");

export interface MovieMock {
  id: string;
  title: string;
  director: string;
  plot: string;
  author: string;
  authorId: string;
  authorAvi: string;
  likes: number;
  likedBy: string[];
  dislikes: number;
  dislikedBy: string[];
  created: string;
  endDate: string;
  movieClubId?: string;
}

type MovieClubMockParams = Partial<MovieMock>;

export async function populateMovieData(params: MovieClubMockParams = {}) {
  logVerbose("Populating movie data...");
  const MoviceClubId = params.movieClubId || "test-club";
  const movieId = params.id || "test-movie";
  const movieData = {
    id: movieId,
    title: params.title || "Test Movie",
    director: params.director || "Test Director",
    plot: params.plot || "Test Plot",
    author: params.author || "Test user",
    authorId: params.authorId || "test-user",
    authorAvi: params.authorAvi || "Test Image",
    likes: params.likes || 0,
    likedBy: params.likedBy || [],
    dislikes: params.dislikes || 0,
    dislikedBy: params.dislikedBy || [],
    created: firebaseAdmin.firestore.Timestamp.fromDate(new Date()),
    endDate: firebaseAdmin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
  };

  const movieRef = firestore.collection("movieclubs").doc(MoviceClubId).collection("movies").doc(movieId);
  try {
    await movieRef.set(movieData);
    logVerbose("Movie data set");
  } catch (error) {
    logError("Error setting movie data:", error);
  };

  return movieData;
}
