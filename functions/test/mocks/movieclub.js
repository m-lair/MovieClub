const { db, admin } = require("firestore")

async function populateMovieClubData(params = {}) {
    console.log("Populating movie club data...");
    const testMoviceClubId = params.id || "Test Club"
    const movieClubData = {
        id: testMoviceClubId,
        name: params.name || "Test Club",
        description: params.description || "Test Description",
        image: params.image || "Test Image",
        ownerID: params.ownerID || "test-user-id",
        ownerName: params.ownerName || "Test User",
        created: admin.firestore.Timestamp.fromDate(new Date()),
        movieEndDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)),
    }
    const movieClubRef = db.collection("movieclubs").doc(testMoviceClubId);
    try {
        await movieClubRef.set(movieClubData);
        console.log("Movie club data set");
    } catch (error) {
        throw new Error(`Error setting movie club data: ${error}`);
    }

    return movieClubData;
}

module.exports = { populateMovieClubData }