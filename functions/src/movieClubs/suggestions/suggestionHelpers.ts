import { firestore, firebaseAdmin } from "firestore";
import { MOVIE_CLUBS, SUGGESTIONS } from "src/utilities/collectionNames";
import { getMovieClubDocRef } from "../movieClubHelpers";

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

export async function getNextSuggestionDoc(clubId: string): Promise<firebaseAdmin.firestore.DocumentSnapshot | null> {
  const suggestionsCollectionRef = getSuggestionsRef(clubId);
  const suggestionsQuery = await suggestionsCollectionRef
    .orderBy('createdAt')
    .limit(1)
    .get();
  return suggestionsQuery.empty ? null : suggestionsQuery.docs[0];
}

function getSuggestionsRef(clubId: string): firebaseAdmin.firestore.CollectionReference {
  return getMovieClubDocRef(clubId).collection('suggestions');
}