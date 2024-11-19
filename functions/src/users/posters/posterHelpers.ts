import { firestore } from "firestore";
import { POSTERS, USERS } from "src/utilities/collectionNames";

export const getPosterRef = (userId: string) => {
    return firestore
        .collection(USERS)
        .doc(userId)
        .collection(POSTERS);
};

export const getPosterDocRef = (userId: string, posterId: string) => {
    return getPosterRef(userId).doc(posterId);
}