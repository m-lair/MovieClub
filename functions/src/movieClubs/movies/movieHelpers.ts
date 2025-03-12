import { firebaseAdmin, firestore } from "firestore";
import { MOVIE_CLUBS, MOVIES } from "src/utilities/collectionNames";

export const getMovieRef = (movieClubId: string) => {
  return firestore
    .collection(MOVIE_CLUBS)
    .doc(movieClubId)
    .collection(MOVIES)
};

// Function to get movie details from TMDB API or fallback to Firestore
export async function getMovieDetails(imdbId: string) {
  try {
    // First try to find the movie in Firestore across all clubs
    const movieQuery = await firestore
      .collectionGroup(MOVIES)
      .where("imdbId", "==", imdbId)
      .limit(1)
      .get();
    
    if (!movieQuery.empty) {
      const movieData = movieQuery.docs[0].data();
      return {
        title: movieData.title || "Unknown Movie",
        imdbId: movieData.imdbId
      };
    }
    
    // If not found in Firestore, return a generic object
    return {
      title: "Unknown Movie",
      imdbId: imdbId
    };
  } catch (error) {
    console.error("Error fetching movie details:", error);
    return {
      title: "Unknown Movie",
      imdbId: imdbId
    };
  }
}

export const getMovieDocRef = (uid: string, movieClubId: string) => {
  return getMovieRef(movieClubId).doc(uid);
};

export const getMovie = async (uid: string, movieClubId: string) => {
  return await getMovieDocRef(uid, movieClubId).get();
};

export const getMovieClubMovieStatus = async (movieClubId: string) => {
  return getMovieRef(movieClubId).where("status", "==", "active").get();
}

// Get the current active movie document
export async function getActiveMovieDoc(clubId: string): Promise<firebaseAdmin.firestore.DocumentSnapshot | null> {
  const movieCollectionRef = getMovieRef(clubId);
  const activeMoviesQuery = await movieCollectionRef
    .where('status', '==', 'active')
    .limit(1)
    .get();
  return activeMoviesQuery.empty ? null : activeMoviesQuery.docs[0];
}