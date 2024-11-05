import { firestore } from "firestore";
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

