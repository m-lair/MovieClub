'use strict';
const test = require('firebase-functions-test')({
    databaseURL: 'localhost:8080',
    projectId: process.env.PROJECT_ID,
}, '/Users/marcus/Library/Mobile Documents/com~apple~CloudDocs/Documents/movieclub-93714-f6efcc256851.json');

const { db, admin } = require('firestore');

async function populateDefaultData(count = 1) {
    console.log('Populating default data...');
    for (let i = 0; i < count; i++) {
        console.log(`Populating data for user ${i}`);
        await populateUserData(i);
        await populateMovieClubData(i);
        await populateMovieData(i);
        await populateMembershipData(i);
        await populateMemberData(i);

    }
}

async function populateUserData(index) {
    const testUserId = `test-user${index}`;
    const testUserData = {
        name: `Test User`,
        id: testUserId,
        image: 'Test Image',
        bio: 'Test Bio',
    };
    try {
        await db.collection('users').doc(testUserId).set(testUserData);
    } catch (error) {
        throw new Error(`Error setting user data: ${error}`);
    }

};

async function populateMovieClubData(index) {
    console.log('Populating movie club data...');
    const movieClubData = {
        name: `Test Club${index}`,
        description: 'Test Description',
        image: 'Test Image',
        created: admin.firestore.Timestamp.fromDate(new Date()),
        movieEndDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)),
    }
    const movieClubRef = db.collection('movieclubs').doc('test-club' + index);
    try {
        await movieClubRef.set(movieClubData);
        console.log('Movie club data set');
    } catch (error) {
        throw new Error(`Error setting movie club data: ${error}`);
    }
}

async function populateMembershipData(index) {
    console.log('Populating membership data...');
    const membershipData = {
        clubID: 'test-club' + index,
        clubName: 'Test Club' + index,
        queue: [{
            title: 'The Matrix',
            author: 'Test user' + index,
            authorID: 'Test user' + index,
            authorAvi: 'Test Image',
            created: admin.firestore.Timestamp.fromDate(new Date()),
            endDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
        }]
    }

    const membershipRef = db.collection('users').doc('test-user' + index).collection('memberships').doc('test-club' + index);
    try {
        await membershipRef.set(membershipData);
        console.log('Membership data set');
    } catch (error) {
        throw new Error(`Error setting membership data: ${error}`);
    }
}

async function populateMovieData(index) {
    console.log('Populating movie data...');
    const movieData = {
        title: 'Test Movie',
        director: 'Test Director',
        plot: 'Test Plot',
        author: 'Test user',
        authorID: 'test-user',
        authorAvi: 'Test Image',
        created: admin.firestore.Timestamp.fromDate(new Date()),
        endDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
    }

    const movieRef = db.collection('movieclubs').doc('test-club' + index).collection('movies').doc();
    try {
        await movieRef.set(movieData);
        console.log('Movie data set');
    } catch (error) {
        throw new Error(`Error setting movie data: ${error}`);
    }
}

async function populateMemberData(index) {
    console.log('Populating member data...');
    const memberData = {
        name: 'Test user' + index,
        id: 'test-member',
        dateAdded: admin.firestore.Timestamp.fromDate(new Date()),
    }
    const memberRef = (await db.collection('movieclubs').get()).docs;
    for (const doc of memberRef) {
        try {
            doc.ref.collection('members').doc('test-user' + index).set(memberData);
            console.log('Member data set');
        } catch (error) {
            throw new Error(`Error setting member data: ${error}`);
        }

    }

}

module.exports = { populateDefaultData }