import { throwHttpsError } from "helpers";
import { MEMBERSHIPS } from "src/utilities/collectionNames";
import { getUserDocRef } from "../userHelpers";

export const getUserMembershipDocRef = (uid: string, movieClubId: string) => {
  return getUserDocRef(uid).collection(MEMBERSHIPS).doc(movieClubId);
};

export const getUserMembership = async (uid: string, movieClubId: string) => {
  return await getUserMembershipDocRef(uid, movieClubId).get();
};

export const verifyMembership = async (uid: string, movieClubId: string) => {
 try {
   const membershipSnap = await getUserMembership(uid, movieClubId);
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
};