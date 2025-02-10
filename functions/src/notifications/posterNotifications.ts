import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { MovieData } from "../movieClubs/movies/movieTypes";
import { UserData } from "src/users/userTypes";
import { getUser } from "src/users/userHelpers";
import { getMovie } from "src/movieClubs/movies/movieHelpers";
import { getMovieClub } from "src/movieClubs/movieClubHelpers";

export const notifyPosterCollected = onDocumentUpdated(
    "movieclubs/{clubId}/movies/{movieId}",
    async (event) => {
    const beforeData = event.data?.before.data() as MovieData;
    const afterData = event.data?.after.data() as MovieData;
    if (!beforeData || !afterData) {
          console.log("Missing poster data");
          return null;
    }
    // Compare collectedBy arrays
    const beforeCollectors: string[] = beforeData.collectedBy || [];
    const afterCollectors: string[] = afterData.collectedBy || [];
    const newCollectors = afterCollectors.filter((userId) => !beforeCollectors.includes(userId));
    if (newCollectors.length === 0) {
          console.log("No new collectors.");
          return null;
    }
    
    // Get New Collectors info
    const collectorPromises = newCollectors.map((userId) =>
        getUser(userId)
    );
    const collectorSnapshots = await Promise.all(collectorPromises);
    const collectorData = collectorSnapshots.map((snapshot) => snapshot.data() as UserData);
    if (collectorData.length === 0) {
          console.log("No collector data found");
          return null;
    }

    // Get the movie author (assume movie doc holds the original author's id)
    const { clubId, movieId } = event.params;
    const movieSnapshot = await getMovie(clubId, movieId);
    const movieData = movieSnapshot.data() as MovieData;
    const movieAuthorId = movieData.userId;

    // Get club info
    const clubSnapshot = await getMovieClub(clubId);
    const clubName = clubSnapshot.data()?.name || "Unnamed Club";

    // Send notification to movie author
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
    for (const collector of collectorData) {
          const userName = collector.name;
          if (!fcmToken) {
                console.log("Collector has no FCM token");
                continue;
          }
    const payload = {
          token: fcmToken,
          notification: {
                title: "Poster Collected",
                body: `Your movie has a new collector: ${userName}`,
          },
          data: {
                type: "collected",
                clubId: clubId,
                movieId: movieData.imdbId
          },
        };

        try {
            const messageId = await admin.messaging().send(payload);
            console.log(
              `Like notification sent to ${movieAuthorId}, msg id: ${messageId}`
            );
          } catch (error) {
            console.error(`Failed to send like notification to ${movieAuthorId}`, error);
          }

          // Write a notification document to the movie author's notifications collection
          try {
            await admin
              .firestore()
              .collection(`users/${movieAuthorId}/notifications`)
              .add({
                clubName: clubName,
                userName: userName,
                othersCount: null,
                message: `Your movie has a new collector!`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                type: "collected",
              });
            console.log("Like notification document written for", movieAuthorId);
          } catch (error) {
            console.error("Failed to write like notification document:", error);
          }
        }
    }
);