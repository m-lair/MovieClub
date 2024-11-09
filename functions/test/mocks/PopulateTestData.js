'use strict';
const test = require('firebase-functions-test')({
    databaseURL: 'localhost:8080',
    projectId: process.env.PROJECT_ID,
}, '/Users/marcus/Library/Mobile Documents/com~apple~CloudDocs/Documents/movieclub-93714-f6efcc256851.json');
const { logVerbose } = require("helpers")

const { db, admin } = require('firestore');

async function populateDefaultData(count = 1) {
    logVerbose('Populating default data...');
    for (let i = 0; i < count; i++) {
        logVerbose(`Populating data for user ${i}`);
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
    logVerbose('Populating movie club data...');
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
        logVerbose('Movie club data set');
    } catch (error) {
        throw new Error(`Error setting movie club data: ${error}`);
    }
}

async function populateMembershipData(index) {
    logVerbose('Populating membership data...');
    const membershipData = {
        clubId: 'test-club' + index,
        clubName: 'Test Club' + index,
        queue: [{
            title: 'The Matrix',
            author: 'Test user' + index,
            authorId: 'Test user' + index,
            authorAvi: 'Test Image',
            created: admin.firestore.Timestamp.fromDate(new Date()),
            endDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
        }]
    }

    const membershipRef = db.collection('users').doc('test-user' + index).collection('memberships').doc('test-club' + index);
    try {
        await membershipRef.set(membershipData);
        logVerbose('Membership data set');
    } catch (error) {
        throw new Error(`Error setting membership data: ${error}`);
    }
}

async function populateMovieData(index) {
    logVerbose('Populating movie data...');
    const movieData = {
        title: 'Test Movie',
        director: 'Test Director',
        plot: 'Test Plot',
        author: 'Test user',
        authorId: 'test-user',
        authorAvi: 'Test Image',
        created: admin.firestore.Timestamp.fromDate(new Date()),
        endDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
    }

    const movieRef = db.collection('movieclubs').doc('test-club' + index).collection('movies').doc();
    try {
        await movieRef.set(movieData);
        logVerbose('Movie data set');
    } catch (error) {
        throw new Error(`Error setting movie data: ${error}`);
    }
}

async function populateMemberData(index) {
    logVerbose('Populating member data...');
    const memberData = {
        name: 'Test user' + index,
        id: 'test-member',
        dateAdded: admin.firestore.Timestamp.fromDate(new Date()),
    }
    const memberRef = (await db.collection('movieclubs').get()).docs;
    for (const doc of memberRef) {
        try {
            doc.ref.collection('members').doc('test-user' + index).set(memberData);
            logVerbose('Member data set');
        } catch (error) {
            throw new Error(`Error setting member data: ${error}`);
        }

    }

}

module.exports = {
    populateDefaultData,
    populateUserData,
    populateMovieClubData,
    populateMembershipData,
    populateMovieData,
    populateMemberData
}