const { db, admin } = require("firestore")

async function populateMovieData(params = {}) {
    console.log("Populating movie data...");
    const MoviceClubId = params.movieClubId || "test-club";
    const movieId = params.id || "test-movie";
    const movieData = {
        id: movieId,
        title: params.title || "Test Movie",
        director: params.director || "Test Director",
        plot: params.plot || "Test Plot",
        author: params.author || "Test user",
        authorID: params.authorID || "test-user",
        authorAvi: params.authorAvi || "Test Image",
        created: admin.firestore.Timestamp.fromDate(new Date()),
        endDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
    };

    const movieRef = db.collection("movieclubs").doc(MoviceClubId).collection("movies").doc(movieId);
    try {
        await movieRef.set(movieData);
        console.log("Movie data set");
    } catch (error) {
        throw new Error(`Error setting movie data: ${error}`);
    };

    return movieData;
}

module.exports = { populateMovieData }