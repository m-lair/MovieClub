import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { MovieData } from "../movieClubs/movies/movieTypes";
import { UserData } from "src/users/userTypes";
import { getUser } from "src/users/userHelpers";
import { getMovieClub } from "src/movieClubs/movieClubHelpers";

export const notifyPosterCollected = onDocumentUpdated(
  "movieclubs/{clubId}/movies/{movieId}",
  async (event) => {
    const beforeData = event.data?.before.data() as MovieData;
    const afterData = event.data?.after.data() as MovieData;
    // Log the event parameters for debugging
    console.log("Club ID:", event.params.clubId);
    console.log("Movie ID:", event.params.movieId);

    if (!beforeData || !afterData) {
      console.log("Missing poster data in before/after snapshots.");
      return null;
    }

    // Compare collectedBy arrays
    const beforeCollectors: string[] = beforeData.collectedBy || [];
    const afterCollectors: string[] = afterData.collectedBy || [];
    const newCollectors = afterCollectors.filter(
      (userId) => !beforeCollectors.includes(userId)
    );

    console.log("Before collectors:", beforeCollectors);
    console.log("After collectors:", afterCollectors);
    console.log("New collectors:", newCollectors);

    if (newCollectors.length === 0) {
      console.log("No new collectors.");
      return null;
    }

    // Get new collectors info
    try {
      const collectorPromises = newCollectors.map((userId) => getUser(userId));
      const collectorSnapshots = await Promise.all(collectorPromises);
      const collectorData = collectorSnapshots.map(
        (snapshot) => snapshot.data() as UserData
      );
      console.log("Collector data array:", collectorData);

      if (collectorData.length === 0) {
        console.log("No collector data found.");
        return null;
      }

      // Get the movie doc
      const { clubId } = event.params;

      // Attempt to read the userId
      const movieAuthorId = afterData.userId;
      console.log("movieAuthorId:", movieAuthorId);

      if (!movieAuthorId) {
        console.log(
          "Movie doc is missing a userId field or userId is undefined."
        );
        return null;
      }
    // Get club info
    const clubSnapshot = await getMovieClub(clubId);
    const clubName = clubSnapshot.data()?.name || "Unnamed Club";

    // Get the movie author's user data
    const authorSnapshot = await getUser(movieAuthorId);
    const authorData = authorSnapshot.data() as UserData;
    if (!authorData) {
      console.log("Movie author not found");
      return null;
    }

    const fcmToken = authorData.fcmToken;
    if (!fcmToken) {
      console.log("Movie author has no FCM token");
      return null;
    }

    // For each new collector, send a notification to the movie author
    for (const collector of collectorData) {
      const userName = collector.name;

      const payload = {
        token: fcmToken,
        notification: {
          title: "Poster Collected",
          body: `Your movie has a new collector: ${userName}`,
        },
        data: {
          type: "collected",
          clubId: clubId,
          movieId: afterData.imdbId, // or use movieId if preferred
        },
      };

      try {
        const messageId = await admin.messaging().send(payload);
        console.log(
          `Collected notification sent to ${movieAuthorId}, msg id: ${messageId}`
        );
      } catch (error) {
        console.error(
          `Failed to send collected notification to ${movieAuthorId}:`,
          error
        );
      }

      // Write a notification document to the movie author's notifications collection
      try {
        await admin
          .firestore()
          .collection(`users/${movieAuthorId}/notifications`)
          .add({
            clubId: clubId,
            clubName: clubName,
            userName: userName,
            userId: authorData.id,
            othersCount: null,
            message: `${userName} collected your movie in ${clubName}`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            type: "collected",
          });
        console.log("Collected notification document written for", movieAuthorId);
      } catch (error) {
        console.error(
          "Failed to write collected notification document:",
          error
        );
      }
    }
      return { success: true };
    } catch (error) {
    
    }
  }
);
