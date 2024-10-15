import { logError, logVerbose } from "helpers";
import { getMovieClubMemberDocRef } from "src/movieClubs/movieClubHelpers";

export interface MemberMock {
  image: string;
  username: string;
  createdAt: number;
}

export interface MemberMockParams {
  userId: string;
  movieClubId: string;
  image?: string;
  username?: string;
  createdAt?: string;
  createMember?: boolean;
}

export async function populateMemberData(params: MemberMockParams) {
  logVerbose("Populating member data...");
  const { movieClubId, userId, createMember = true } = params;

  const memberData: MemberMock = {
    image: params.image || "Test Image",
    username: params.username || "Test Username",
    createdAt: Date.now(),
  };

  const memberRef = getMovieClubMemberDocRef(userId, movieClubId)

  try {
    if (createMember) {
      await memberRef.set(memberData);
    }

    logVerbose("Membership data set");
  } catch (error) {
    logError("Error setting member data:", error);
  }

  return memberData;
}
