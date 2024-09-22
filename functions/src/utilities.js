const functions = require("firebase-functions");

const verifyRequiredFields = (data, requiredFields) => {
  const missingFields = requiredFields.filter(field => !data?.[field]);

  if (missingFields.length > 0) {
    throwHttpsError("invalid-argument", `The function must be called with ${missingFields.join(', ')}.`, data);
  };
};

const logVerbose = (message) => {
  if (process.env.LOG_LEVEL == "verbose") {
    console.log(message);
  };
};

const logError = (message, error) => {
  if (process.env.ERROR_LEVEL == "verbose") {
    console.error(message, error);
  };
};

const handleCatchHttpsError = (message, error) => {
  logError(message, error);

  if (error instanceof functions.https.HttpsError) {
    throw error;
  } else {
    throwHttpsError("internal", error.message, error);
  };
};

const throwHttpsError = (cause, message, details = {}) => {
  throw new functions.https.HttpsError(cause, message, details);
};

module.exports = { handleCatchHttpsError, logError, logVerbose, throwHttpsError, verifyRequiredFields };