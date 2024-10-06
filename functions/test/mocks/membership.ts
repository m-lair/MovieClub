import { logError, logVerbose } from "helpers";
import { firestore } from "firestore";

export interface MembershipMock {
  movieClubName: string;
  createdAt: number;
}

export interface MembershipMockParams {
  userId: string;
  movieClubId: string;
  movieClubName: string;
  createMembership?: boolean;
};

export async function populateMembershipData(params: MembershipMockParams) {
  logVerbose('Populating membership data...');
  const { createMembership = true } = params;

  const userId = params.userId || 'test-user';
  const movieClubId = params.movieClubId || 'test-club';

  const membershipData: MembershipMock = {
    movieClubName: params.movieClubName || 'Test Club',
    createdAt: Date.now()
  };

  const membershipRef = firestore.collection('users').doc(userId).collection('memberships').doc(movieClubId);
  try {
    if (createMembership) {
      await membershipRef.set(membershipData);
    }

    logVerbose('Membership data set');
  } catch (error) {
    logError("Error setting membership data:", error);
  }

  return membershipData
};
