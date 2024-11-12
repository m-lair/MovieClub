import { firestore } from "firestore";
import { MOVIE_CLUBS, SUGGESTIONS } from "src/utilities/collectionNames";

export const getMovieClubSuggestionRef = (movieClubId: string) => {
  return firestore
    .collection(MOVIE_CLUBS)
    .doc(movieClubId)
    .collection(SUGGESTIONS)
};

export const getMovieClubSuggestionDocRef = (uid: string, clubId: string) => {
  return getMovieClubSuggestionRef(clubId).doc(uid);
};

export const getMovieClubSuggestion = async (uid: string, clubId: string) => {
  return await getMovieClubSuggestionDocRef(uid, clubId).get()
};