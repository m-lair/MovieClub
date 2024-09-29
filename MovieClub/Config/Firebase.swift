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
import UserNotifications
import FirebaseAuth
import FirebaseFirestoreSwift
import AuthenticationServices
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAnalytics
import SwiftData


func configureFirebase() {
    FirebaseApp.configure()
    #if DEBUG
    let env = ProcessInfo.processInfo.environment
    if let emulatorHost = env["FIREBASE_EMULATOR_HOST"],
       let authPortString = env["AUTHENTICATION_PORT"],
       let firestorePortString = env["FIRESTORE_PORT"],
       let authPort = Int(authPortString),
       let firestorePort = Int(firestorePortString) {
        Auth.auth().useEmulator(withHost: emulatorHost, port: authPort)
        
        let settings = Firestore.firestore().settings
        settings.host = "localhost:\(firestorePort)"
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
    }
    #endif
}
    
    

