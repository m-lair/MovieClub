/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// import {onRequest} from "firebase-functions/v2/https";
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

require("module-alias/register");
import 'tsconfig-paths/register';

const config = require("./config");

import * as comments from "./movieClubs/movies/comments/commentFunctions";
const movies = require("./movieClubs/movies/movieFunctions");
const movieClubs = require("./movieClubs/movieClubFunctions");
const users = require("./users/userFunctions");

export { comments, config, movies, movieClubs, users };
