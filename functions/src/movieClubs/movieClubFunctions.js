"use strict";

const functions = require("firebase-functions");
const { db } = require("firestore");
const { verifyRequiredFields } = require("utilities")

exports.createMovieClub = functions.https.onCall(async (data, context) => {
    const requiredFields = ["name", "ownerID", "ownerName", "isPublic", "timeInterval", "bannerUrl"]
    verifyRequiredFields(data, requiredFields)

    try {
        const movieClubRef = db.collection("movieclubs")

        const movieClubData = {
            name: data.name,
            ownerID: data.ownerID,
            ownerName: data.ownerName,
            isPublic: data.isPublic,
            timeInterval: data.timeInterval,
            bannerUrl: data.bannerUrl
        }

        const movieClub = await movieClubRef.add(movieClubData);

        console.log("Movie Club created successfully!");

        return movieClub
    } catch (error) {
        console.error("Error creating Movie Club:", error);
    }
})

exports.updateMovieClub = functions.https.onCall(async (data, context) => {
    const requiredFields = ["movieClubId"]
    verifyRequiredFields(data, requiredFields)

    try {
        const movieClubRef = db.collection("movieclubs").doc(data.movieClubId)

        const movieClubData = {
            ...(data.name && { name: data.name }),
            ...(data.ownerID && { ownerID: data.ownerID }),
            ...(data.ownerName && { ownerName: data.ownerName }),
            ...(data.isPublic != undefined && { isPublic: data.isPublic }),
            ...(data.timeInterval && { timeInterval: data.timeInterval }),
            ...(data.bannerUrl && { bannerUrl: data.bannerUrl }),
        }

        await movieClubRef.update(movieClubData);

        console.log("Movie Club updated successfully!");
    } catch (error) {
        console.error("Error updating Movie Club:", error);
    }
})