const test = require("firebase-functions-test")({
    projectId: process.env.PROJECT_ID,
    databaseURL: 'localhost:8080',
});

module.exports = { test }