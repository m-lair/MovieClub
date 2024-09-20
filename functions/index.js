const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const movies = require('./firestore/movieFunctions')
const movie_clubs = require('./firestore/movieClubFunctions')
const users = require('./firestore/userFunctions')

module.exports = { movies, movie_clubs, users } 