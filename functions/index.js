require('module-alias/register');

const config = require('./config')
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const movies = require('./src/movieClubs/movies/movieFunctions')
const movie_clubs = require('./src/movieClubs/movieClubFunctions')
const users = require('./src/users/userFunctions')

module.exports = { movies, movie_clubs, users, config } 