import { logError, logVerbose } from "helpers";
import { firestore, firebaseAdmin } from "firestore";

export interface MovieClubMock {
  id: string;
  bannerUrl: string;
  description: string;
  image: string;
  isPublic: boolean;
  name: string;
  ownerId: string;
  ownerName: string;
  timeInterval: string;
  createdAt: string | firebaseAdmin.firestore.FieldValue;
}

type MovieClubMockParams = Partial<MovieClubMock>;

export async function populateMovieClubData(params: MovieClubMockParams = {}): Promise<MovieClubMock> {
  logVerbose("Populating movie club data...");
  const testMoviceClubId = params.id || "Test Club";
  const movieClubData: MovieClubMock = {
    id: testMoviceClubId,
    bannerUrl: params.bannerUrl || "Test Banner Url",
    description: params.description || "Test Description",
    image: params.image || "Test Image",
    isPublic: (params.isPublic != undefined) && params.isPublic,
    name: params.name || "Test Club",
    ownerId: params.ownerId || "test-user-id",
    ownerName: params.ownerName || "Test User",
    timeInterval: params.timeInterval || "",
    createdAt: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
    // movieEndDate: firebaseAdmin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)),
  };

  const movieClubRef = firestore.collection("movieclubs").doc(testMoviceClubId);
  try {
    await movieClubRef.set(movieClubData);
    logVerbose("Movie club data set");

  } catch (error) {
    logError("Error setting movie club data:", error);
  };

  return movieClubData;
};