const functions = require("firebase-functions");

const verifyRequiredFields = (data, requiredFields) => {
    const missingFields = requiredFields.filter(field => !data?.[field]);

    if (missingFields.length > 0) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            `The function must be called with ${missingFields.join(', ')}.`
        );
    }
}

const logVerbose = (message) => {
  if (process.env.LOG_LEVEL == "verbose") {
    console.log(message)
  }
}

module.exports = { logVerbose, verifyRequiredFields }