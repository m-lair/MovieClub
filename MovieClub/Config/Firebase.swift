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
    // Configure Firebase using GoogleService-Info.plist for both local and cloud builds
    FirebaseApp.configure()
    print("Firebase configured with GoogleService-Info.plist")
    
#if DEBUG
    // Configure Firebase emulators for debugging
    configureEmulators()
    print("Firestore host: \(Firestore.firestore().settings.host)")
#endif
}

#if DEBUG
private func configureEmulators() {
    // Auth emulator
    Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
    Auth.auth().settings?.isAppVerificationDisabledForTesting = true
    
    // Cloud Functions emulator
    Functions.functions().useEmulator(withHost: "127.0.0.1", port: 5001)
    
    // Firestore emulator
    let settings = Firestore.firestore().settings
    settings.host = "127.0.0.1:8080"
    settings.cacheSettings = MemoryCacheSettings()
    settings.isSSLEnabled = false
    Firestore.firestore().settings = settings
}
#endif
    
    

