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
        data.collectedDate = new Date();
        const posterRef = getPosterDocRef(uid, data.id);
      
        const posterDoc = await posterRef.get();
        if (posterDoc.exists) {
          throw new functions.https.HttpsError(
          "already-exists",
          "Poster has already been collected."
          );
        }
        
        await posterRef.set(data);
        logVerbose("Poster collected successfully!");

        // update movie stats
        const movieRef = getMovieDocRef(data.id, data.clubId);
        try {
          const movieDoc = await movieRef.get(); // Check if the document exists
          if (movieDoc.exists) {
              await movieRef.update({ 
                  collectedBy: firebaseAdmin.firestore.FieldValue.arrayUnion(uid),
                  numCollected: firebaseAdmin.firestore.FieldValue.increment(1)
              });
              logVerbose("Movie document updated successfully.");
          } else {
              logVerbose("Movie document does not exist.");
          }
      } catch (error) {
          logVerbose("Error updating movie document:");
      }

      return posterRef.id;
    } catch (error) {
        console.log(error)
        handleCatchHttpsError("Error Collecting Poster:", error);
    }
  }
);
