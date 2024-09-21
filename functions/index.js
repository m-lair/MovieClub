require("module-alias/register");

const config = require("./config")

const comments = require("./src/movieClubs/movies/comments/commentFunctions")
const movies = require("./src/movieClubs/movies/movieFunctions")
const movie_clubs = require("./src/movieClubs/movieClubFunctions")
const users = require("./src/users/userFunctions")

module.exports = { comments, config, movies, movie_clubs, users } 