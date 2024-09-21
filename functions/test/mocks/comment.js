const { db } = require("firestore")

async function populateCommentData(params = {}) {
    console.log('Populating comment data...');
    const movieClubId = params.movieClubId || "test-club-id"
    const movieId = params.movieId || "test-movie-id"
    const name = params.name || 'Test user'
    const id = params.id || 'test-comment-id'

    const commentData = {
        id: id,
        image: params.image || "Test image",
        text: params.text || "Test text",
        userID: params.username || "test-user-id",
        username: params.username || "Test User",
        likes: params.likes || 0,
        date: admin.firestore.Timestamp.fromDate(new Date()),
    }

    const commentsRef = db.collection("movieclubs").doc(movieClubId).collection('movies').doc(movieId).collection('comments').doc(id)
    try {
        await commentsRef.set(commentData);
        console.log('comment data set');
    } catch (error) {
        throw new Error(`Error setting comment data: ${error}`);
    }
}

module.exports = { populateCommentData }