import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";
import { verifyMembership } from "src/users/memberships/membershipHelpers";
import { CreateMovieClubSuggestionData, DeleteMovieClubSuggestionData } from "./suggestionTypes";
import { getMovieClubSuggestionDocRef } from "./suggestionHelpers";

import {
  handleCatchHttpsError,
  logVerbose,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";

exports.createMovieClubSuggestion = functions.https.onCall(
  async (request: CallableRequest<CreateMovieClubSuggestionData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);

      const requiredFields = ["imageUrl", "movieClubId", "title", "username"];
      verifyRequiredFields(data, requiredFields);
      await verifyMembership(uid, data.movieClubId);

      const suggestionRef = getMovieClubSuggestionDocRef(uid, data.movieClubId);

      const suggestionData = {
        title: data.title,
        //imageUrl: data.imageUrl,
        username: data.username,
        createdAt: Date.now()
      };

      await suggestionRef.set(suggestionData);

      logVerbose("Suggestion created successfully!");

      return;
    } catch (error) {
      handleCatchHttpsError("Error creating Suggestion:", error);
    };
  }
);

exports.deleteUserMovieClubSuggestion = functions.https.onCall(
  async (request: CallableRequest<DeleteMovieClubSuggestionData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);

      const requiredFields = ["movieClubId"];
      verifyRequiredFields(data, requiredFields);

      const suggestionRef = getMovieClubSuggestionDocRef(uid, data.movieClubId);

      await suggestionRef.delete();

      logVerbose("Suggestion deleted successfully!");

      return;
    } catch (error) {
      handleCatchHttpsError("Error deleting Suggestion:", error);
    }
  }
);