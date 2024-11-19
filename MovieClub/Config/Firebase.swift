//
//  Firebase.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/28/24.
//

import Firebase
import SwiftUI
import Observation
import FirebaseCore
import Foundation
import FirebaseFunctions
import UserNotifications
import FirebaseAuth
import AuthenticationServices
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAnalytics
import SwiftData


func configureFirebase() {
    // Attempt to initialize Firebase with options from environment variables
    if let apiKey = ProcessInfo.processInfo.environment["FIREBASE_API_KEY"],
       let appID = ProcessInfo.processInfo.environment["FIREBASE_APP_ID"],
       let projectID = ProcessInfo.processInfo.environment["FIREBASE_PROJECT_ID"],
       let gcmSenderID = ProcessInfo.processInfo.environment["FIREBASE_GCM_SENDER_ID"],
       let bundleID = Bundle.main.bundleIdentifier {
        
        // Initialize Firebase options
        let options = FirebaseOptions(googleAppID: appID, gcmSenderID: gcmSenderID)
        options.apiKey = apiKey
        options.projectID = projectID
        options.bundleID = bundleID
        // Configure Firebase with the options
        print("configuring firebase")
        FirebaseApp.configure(options: options)
    } else {
        // Fallback to using GoogleService-Info.plist
        FirebaseApp.configure()
        print("Firebase configured with GoogleService-Info.plist.")
    }
#if DEBUG
    // Configure Firebase emulators for debugging
    Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
    Auth.auth().settings?.isAppVerificationDisabledForTesting = true
    Functions.functions().useEmulator(withHost: "127.0.0.1", port: 5001)
    let settings = Firestore.firestore().settings
    settings.host = "127.0.0.1:8080"
    settings.cacheSettings = MemoryCacheSettings()
    settings.isSSLEnabled = false
    Firestore.firestore().settings = settings
#endif
}
    
    

