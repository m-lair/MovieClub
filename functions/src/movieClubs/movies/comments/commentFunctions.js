const { db } = require('firestore');
const { verifyRequiredFields } = require("utilities")

async function postComment(movieClubId, movieId, commentData) {
    requiredFields = ["text", "userID", "username"]
    verifyRequiredFields(commentData, requiredFields)

    try {
        // Reference to the specific movie's comments collection
        const commentsRef = db
            .collection('movieclubs')
            .doc(movieClubId)
            .collection('movies')
            .doc(movieId)
            .collection('comments');

        // Add the comment to the 'comments' sub-collection
        await commentsRef.add({
            ...commentData,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log('Comment posted successfully!');
    } catch (error) {
        console.error('Error posting comment:', error);
    }
}