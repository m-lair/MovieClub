// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
const functions = require('firebase-functions/v1');

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
admin.initializeApp();

exports.rotateMovie = functions.pubsub.schedule('every 24 hours').onRun((context) => {
    const db = admin.firestore();
    const apiEndpoint = "http://www.omdbapi.com/?apikey=5a0e3a3a&r=json";
    
    return db.collectionGroup("movies")
        .where("movieEndDate", "<", Date.now())
        .get()
        .then((snapshot) => {
            const promises = [];
            snapshot.forEach((doc) => {
                const membership = doc.data();
                const movie = membership.queue[0];
                const clubID = doc.ref.parent.parent.id;
                const userID = doc.ref.parent.parent.parent.id;
                const clubRef = db.collection("movieclubs").doc(clubID);
                const userRef = db.collection("users").doc(userID);
                
                promises.push(userRef.get().then((userDoc) => {
                    const userData = userDoc.data();
                    return fetch(`${apiEndpoint}&t=${movie.title}`)
                        .then((response) => response.json())
                        .then((data) => {
                            const movieData = {
                                title: data.Title,
                                director: data.Director,
                                plot: data.Plot,
                                author: userData.name,
                                authorID: userData.id,
                                authorAvi: userData.image,
                                created: Date.now(),
                                endDate: Date.now() + (1000 * 60 * 60 * 24 * 7)
                            };
                            return clubRef.collection("movies").add(movieData);
                        });
                }));
            });
            return Promise.all(promises);
        });
})