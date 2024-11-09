import { firestore } from "firestore";
import { USERS } from "src/utilities/collectionNames";

export const getUserRef = () => {
  return firestore.collection(USERS);
};

export const getUserDocRef = (uid: string) => {
  return getUserRef().doc(uid);
};

export const getUser = async (uid: string) => {
  return await getUserDocRef(uid).get();
};