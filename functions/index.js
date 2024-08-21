/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Firestore } = require('firebase-admin/firestore');
const axios = require('axios');
admin.initializeApp();

exports.scheduledUpdateNextMovieDateAdded = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
    const now = new Date();

    try {
        // Get all MovieClubs
        const movieClubsRef = admin.firestore().collection('movieclubs');
        const movieClubsSnapshot = await movieClubsRef.get();

        // Loop through each MovieClub
        for (const clubDoc of movieClubsSnapshot.docs) {
            const clubId = clubDoc.id;
            const moviesRef = clubDoc.ref.collection('movies')
            const moviesQuery = await moviesRef.orderBy("created", 'desc').findNearest().get();
            const movieData = moviesQuery.docs[0].data();
            // Movie needs to be updated i.e. watch period has been met
            if (movieData.endDate && movieData.endDate.toDate() <= now) {
                //get member who is next up
                let membersRef = clubDoc.ref.collection('members').orderBy("dateAdded", 'asc').findNearest().get();
                let memberData = (await membersRef).docs.at(0).ref;
                memberData.update({"dateAdded": admin.firestore.Timestamp.now()});
                //get the user obejct from userID
                let userID = memberData.userID;
                let usersCollectionRef = admin.firestore().collection("users");
                //get membership of user
                let user = await usersCollectionRef.doc(userID).get();
                let queue = user.collection("memberships").doc(clubId).data().queue;
                //get movie from next users queue
                if (queue && queue.length > 0) {
                    const movie = queue[0];
                    // Get the movie title and place it in the movies collection in the MovieClub
                    let movieTitle = movie.title; // Assuming the movie object has a 'title' attribute
                    let oldEndDate = clubDoc.data().movieEndDate;

                    if (oldEndDate) {
                    oldEndDate = oldEndDate.toDate(); // Convert Firestore timestamp to JavaScript Date
                    let weeksToAdd = clubDoc.timeInverval;
                    const newEndDate = new Date(oldEndDate.getTime() + weeksToAdd * 7 * 24 * 60 * 60 * 1000);
                    
                    const movieApiResponse = await axios.get(`https://omdbapi.com/?t=${movieTitle}&apikey=ab92d369`);
                    const apiData = movieApiResponse.data;
                    
                    //build next movie
                        const movieData = {
                        title: movieTitle,
                        addedBy: userID,
                        author: user.name,
                        authorID: user.id,
                        authorAvi: user.image,
                        plot: apiData.Plot,
                        endDate: admin.firestore.Timestamp.fromDate(newEndDate),
                        releaseYear: apiData.Year,
                        director: apiData.Director,
                        poster: apiData.Poster
                        };
                        moviesRef.add(movieData);
                    }
                }
                //update member date added

                //done
                console.log(`Updated dateAdded for MovieClub: ${clubId}, Movie: ${movieDoc.id}`);
        }
    }
        console.log('Successfully updated dateAdded for all applicable members.');
 } catch (error) {
        console.error('Error updating dateAdded:', error);
 }
});