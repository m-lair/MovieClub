import { firestore } from "firestore";
import { MEMBERS, MOVIE_CLUBS } from "src/utilities/collectionNames";

export const getMovieClubRef = () => {
  return firestore.collection(MOVIE_CLUBS);
};

export const getMovieClubDocRef = (movieClubId: string) => {
  return getMovieClubRef().doc(movieClubId);
};

export const getMovieClub = async (movieClubId: string) => {
  return await getMovieClubDocRef(movieClubId).get();
};

export const getMovieClubMemberRef = (movieClubId: string) => {
  return getMovieClubDocRef(movieClubId).collection(MEMBERS);
};

export const getMovieClubMemberDocRef = (uid: string, movieClubId: string) => {
  return getMovieClubMemberRef(movieClubId).doc(uid);
};

export const getMovieClubMember = async (uid: string, movieClubId: string) => {
  return await getMovieClubMemberDocRef(uid, movieClubId).get();
};