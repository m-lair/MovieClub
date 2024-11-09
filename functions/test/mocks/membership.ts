import { logError, logVerbose } from "helpers";
import { getUserMembershipDocRef } from "src/users/memberships/membershipHelpers";

export interface MembershipMock {
  movieClubName: string;
  createdAt: number;
}

export interface MembershipMockParams {
  userId: string;
  movieClubId: string;
  movieClubName?: string;
  createMembership?: boolean;
}

export async function populateMembershipData(params: MembershipMockParams) {
  logVerbose("Populating membership data...");
  const { movieClubId, userId, createMembership = true } = params;

  const membershipData: MembershipMock = {
    movieClubName: params.movieClubName || "Test Club",
    createdAt: Date.now(),
  };

  const membershipRef = getUserMembershipDocRef(userId, movieClubId)

  try {
    if (createMembership) {
      await membershipRef.set(membershipData);
    }

    logVerbose("Membership data set");
  } catch (error) {
    logError("Error setting membership data:", error);
  }

  return membershipData;
};
