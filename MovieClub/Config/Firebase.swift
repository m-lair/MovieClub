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
    
    Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
    Functions.functions().useEmulator(withHost: "127.0.0.1", port: 5001)
    let settings = Firestore.firestore().settings
    settings.host = "127.0.0.1:8080"
    settings.cacheSettings = MemoryCacheSettings()
    settings.isSSLEnabled = false
    Firestore.firestore().settings = settings
    
#endif
    print(Firestore.firestore().settings.host)
}
    
    

