import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";
import { verifyAuth, verifyRequiredFields, throwHttpsError, logVerbose, handleCatchHttpsError } from "helpers";
import { getMovieClub, getMovieClubMemberDocRef } from "src/movieClubs/movieClubHelpers";
import { getUserMembershipDocRef } from "./membershipHelpers";
import { JoinMovieClubData, LeaveMovieClubData } from "./membershipTypes";
import { getMovieClubSuggestionDocRef } from "src/movieClubs/suggestions/suggestionHelpers";

exports.joinMovieClub = functions.https.onCall(
  async (request: CallableRequest<JoinMovieClubData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);

      const requiredFields = [
        //"image",
        "clubId",
        "clubName",
        "userName",
      ];
      verifyRequiredFields(data, requiredFields);
      console.log("data", data);
      const movieClubRef = await getMovieClub(data.clubId)
      const movieClubData = movieClubRef.data();

      if (movieClubData !== undefined && !movieClubData.isPublic) {
        throwHttpsError(
          "permission-denied",
          "The Movie Club is not publicly joinable.",
        );
      };

      const userMembershipsRef = getUserMembershipDocRef(uid, data.clubId);
      await userMembershipsRef.set({
        movieClubName: data.clubId,
        createdAt: Date.now(),
      });

      const movieClubMemberRef = getMovieClubMemberDocRef(uid, data.clubId);
      await movieClubMemberRef.set({
        image: data.image,
        username: data.userName,
        createdAt: Date.now(),
      });

      return { success: true };

      logVerbose("User joined Movie Club successfully!");
    } catch (error: any) {
      handleCatchHttpsError(`Error joining movie club`, error);
    }
  }
);

exports.leaveMovieClub = functions.https.onCall(
  async (request: CallableRequest<LeaveMovieClubData>): Promise<void> => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);
      console.log(data)
      const requiredFields = ["clubId"];
      verifyRequiredFields(data, requiredFields);

      const movieClubSuggestionRef = getMovieClubSuggestionDocRef(uid, data.clubId)
      await movieClubSuggestionRef.delete();

      const userMembershipsRef = getUserMembershipDocRef(uid, data.clubId);
      await userMembershipsRef.delete();

      const movieClubMemberRef = getMovieClubMemberDocRef(uid, data.clubId);
      await movieClubMemberRef.delete();

      logVerbose("User left Movie Club successfully!");
    } catch (error: any) {
      handleCatchHttpsError(`Error leaving movie club`, error);
    };
  }
);