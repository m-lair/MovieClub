import * as functions from "firebase-functions";
import { firestore } from "firestore";
import {
  handleCatchHttpsError,
  verifyAuth,
  verifyRequiredFields,
} from "helpers";
import { CallableRequest } from "firebase-functions/https";

interface DeleteNotificationData {
  notificationId: string;
}

exports.deleteNotification = functions.https.onCall(
  async (request: CallableRequest<DeleteNotificationData>) => {
    try {
      const { data, auth } = request;
      const { uid } = verifyAuth(auth);
      
      // Verify required fields
      const requiredFields = ["notificationId"];
      verifyRequiredFields(data, requiredFields);

      const { notificationId } = data;

      // Reference to the notification document
      const notificationRef = firestore
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(notificationId);

      // Delete the notification
      await notificationRef.delete();

      return { success: true };
    } catch (error: any) {
      handleCatchHttpsError("Error deleting notification:", error);
    }
  }
); 