import { firestore } from "firestore";
import { throwHttpsError } from "helpers";
import { USERS, MEMBERSHIPS } from "src/utilities/collectionNames";

export const verifyMembership = async (uid: string, movieClubId: string) => {
  const membershipRef = firestore
    .collection(USERS)
    .doc(uid)
    .collection(MEMBERSHIPS)
    .doc(movieClubId);
 try {
   const membershipSnap = await membershipRef.get();
   const membershipData = membershipSnap.data();
   
   if (membershipData === undefined) {
     throwHttpsError(
       "permission-denied",
       "You are not a member of this Movie Club.",
      );
    };
  } catch(error) {
    throw error;
  };
} ;