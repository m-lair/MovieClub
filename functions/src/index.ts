// @ts-nocheck

require("module-alias/register");

import * as config from "../config";

import * as comments from "./movieClubs/movies/comments/commentFunctions";
import * as movies from "./movieClubs/movies/movieFunctions";
import * as movieClubs from "./movieClubs/movieClubFunctions";
import * as users from "./users/userFunctions";

export { comments, config, movies, movieClubs, users } 