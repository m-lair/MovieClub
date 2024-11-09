import * as functions from "firebase-functions";
import { AuthData } from "firebase-functions/tasks";

export const verifyRequiredFields = (
  data: Record<string, any>,
  requiredFields: Array<string>,
) => {
  const missingFields = requiredFields.filter((field) => !data?.[field]);

  if (missingFields.length > 0) {
    throwHttpsError(
      "invalid-argument",
      `The function must be called with ${missingFields.join(", ")}.`,
      data,
    );
  }
};

export const verifyAuth = (auth: AuthData | undefined): AuthData => {
  if (!auth) {
    throwHttpsError("unauthenticated", "auth object is undefined.");
  }

  return auth!;
};

export const logVerbose = (message: string) => {
  if (process.env.LOG_LEVEL == "verbose") {
    console.log(message);
  }
};

export const logError = (message: string, error: any) => {
  if (process.env.ERROR_LEVEL == "verbose") {
    console.error(message, error);
  }
};

export const handleCatchHttpsError = (message: string, error: any) => {
  logError(message, error);

  if (error instanceof functions.https.HttpsError) {
    throw error;
  } else {
    throwHttpsError("internal", error.message, error);
  }
};

export const throwHttpsError = (
  cause: functions.https.FunctionsErrorCode,
  message: string,
  details = {},
): functions.https.HttpsError => {
  throw new functions.https.HttpsError(cause, message, details);
};
