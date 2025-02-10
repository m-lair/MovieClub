import { firebaseAdmin, firestore } from "firestore";
import { MOVIE_CLUBS, MOVIES } from "src/utilities/collectionNames";

export const getMovieRef = (movieClubId: string) => {
  return firestore
    .collection(MOVIE_CLUBS)
    .doc(movieClubId)
    .collection(MOVIES)
};

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