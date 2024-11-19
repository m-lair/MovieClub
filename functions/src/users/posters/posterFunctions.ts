import * as functions from "firebase-functions";
import { CallableRequest } from "firebase-functions/https";

import {
  handleCatchHttpsError,
  logVerbose,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { getPosterDocRef } from "./posterHelpers";
import { CollectPosterData } from "./posterTypes";
import { getMovieDocRef } from "src/movieClubs/movies/movieHelpers";
import { firebaseAdmin } from "firestore";

exports.collectPoster = functions.https.onCall(
  async (request: CallableRequest<CollectPosterData>) => {
    try {
        const { data, auth } = request;
        const { uid } = verifyAuth(auth);
        const requiredFields = ["id", "clubId"];
        verifyRequiredFields(data, requiredFields);

        const posterRef = getPosterDocRef(uid, data.id);
        await posterRef.set(data);
        
        logVerbose("Poster collected successfully!");

        // update movie stats
        const movieRef = getMovieDocRef(data.id, data.clubId);
        await movieRef.update({ 
            collectedBy: firebaseAdmin.firestore.FieldValue.arrayUnion(uid),
            numCollected: firebaseAdmin.firestore.FieldValue.increment(1)
        });

        return { success: true };

    } catch (error) {
        console.log(error)
        handleCatchHttpsError("Error deleting Suggestion:", error);
    }
  }
);