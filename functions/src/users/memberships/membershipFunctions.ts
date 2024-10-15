import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";
import { verifyAuth, verifyRequiredFields, throwHttpsError, logVerbose, handleCatchHttpsError } from "helpers";
import { getMovieClub, getMovieClubMemberDocRef } from "src/movieClubs/movieClubHelpers";
import { getUserMembershipDocRef } from "./membershipHelpers";
import { JoinMovieClubData, LeaveMovieClubData } from "./membershipTypes";
import { getMovieClubSuggestionDocRef } from "src/movieClubs/suggestions/suggestionHelpers";

exports.joinMovieClub = functions.https.onCall(
  async (request: CallableRequest<JoinMovieClubData>): Promise<void> => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);

      const requiredFields = [
        "image",
        "movieClubId",
        "movieClubName",
        "username",
      ];
      verifyRequiredFields(data, requiredFields);

      const movieClubRef = await getMovieClub(data.movieClubId)
      const movieClubData = movieClubRef.data();

      if (movieClubData !== undefined && !movieClubData.isPublic) {
        throwHttpsError(
          "permission-denied",
          "The Movie Club is not publicly joinable.",
        );
      };

      const userMembershipsRef = getUserMembershipDocRef(uid, data.movieClubId);
      await userMembershipsRef.set({
        movieClubName: data.movieClubName,
        createdAt: Date.now(),
      });

      const movieClubMemberRef = getMovieClubMemberDocRef(uid, data.movieClubId);
      await movieClubMemberRef.set({
        image: data.image,
        username: data.username,
        createdAt: Date.now(),
      });

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

      const requiredFields = ["movieClubId"];
      verifyRequiredFields(data, requiredFields);

      const movieClubSuggestionRef = getMovieClubSuggestionDocRef(uid, data.movieClubId)
      await movieClubSuggestionRef.delete();

      const userMembershipsRef = getUserMembershipDocRef(uid, data.movieClubId);
      await userMembershipsRef.delete();

      const movieClubMemberRef = getMovieClubMemberDocRef(uid, data.movieClubId);
      await movieClubMemberRef.delete();

      logVerbose("User left Movie Club successfully!");
    } catch (error: any) {
      handleCatchHttpsError(`Error leaving movie club`, error);
    };
  }
);