require('module-alias/register');

const config = require('./config')
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}


const movies = require('./firestore/movieClubs/movies/movieFunctions')
const movie_clubs = require('./firestore/movieClubs/movieClubFunctions')
const users = require('./firestore/users/userFunctions')

module.exports = { movies, movie_clubs, users, config } 