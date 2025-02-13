import { firestore } from "firestore";
import { COMMENTS, MOVIE_CLUBS, MOVIES } from "src/utilities/collectionNames";

export const getCommentsRef = (clubId: string, movieId: string) => {
  return firestore
    .collection(MOVIE_CLUBS)
    .doc(clubId)
    .collection(MOVIES)
    .doc(movieId)
    .collection(COMMENTS);
};

export const getCommentsDocRef = (clubId: string, movieId: string, commentId: string) => {
  return getCommentsRef(clubId, movieId).doc(commentId);
};

export const getComment = async (movieId: string, clubId: string, commentId: string) => {
  return await getCommentsDocRef(movieId, clubId, commentId).get();
};