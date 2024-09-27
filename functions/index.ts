require("module-alias/register");
import 'tsconfig-paths/register';

const config = require("./config");

import * as comments from "./src/movieClubs/movies/comments/commentFunctions";
const movies = require("./src/movieClubs/movies/movieFunctions");
const movieClubs = require("./src/movieClubs/movieClubFunctions");
const users = require("./src/users/userFunctions");

export { comments, config, movies, movieClubs, users };