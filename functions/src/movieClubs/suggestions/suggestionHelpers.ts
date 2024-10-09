import { firestore } from "firestore";
import { MOVIE_CLUBS, SUGGESTIONS } from "src/utilities/collectionNames";

export const getMovieClubSuggestionRef = (movieClubId: string) => {
  return firestore
    .collection(MOVIE_CLUBS)
    .doc(movieClubId)
    .collection(SUGGESTIONS)
};

export const getMovieClubSuggestionDocRef = (uid: string, movieClubId: string) => {
  return getMovieClubSuggestionRef(movieClubId).doc(uid);
};