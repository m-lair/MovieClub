//
//  MovieClubApp.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import SwiftUI
import Observation
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct MovieClubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var service = AuthService()
    var body: some Scene {
        
        WindowGroup {
            ContentView()
        }
        .environment(service)
    }
}
