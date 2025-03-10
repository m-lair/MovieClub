//
//  MovieClubApp.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//
import Firebase
import SwiftUI
import Observation
import FirebaseCore
import Foundation
import UserNotifications
import FirebaseAuth
import AuthenticationServices
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        configureFirebase()
        
        configureUserNotifications()
        
        Messaging.messaging().delegate = self
        Analytics.setAnalyticsCollectionEnabled(true)
        return true
    }
    
    private func configureUserNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("User declined notification permissions.")
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            Messaging.messaging().apnsToken = deviceToken
        }

    // Handle notification when user interacts with it
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        _ = response.notification.request.content.userInfo
        // Handle navigation or other actions based on the notification's payload
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        // 1) If the user is logged in, store it immediately.
        if Auth.auth().currentUser?.uid != nil {
            Task {
                print("calling storeFCMTokenIfAuthenticated")
                let dataManager = DataManager()
                // Use try-catch to handle errors properly
                do {
                    try await dataManager.storeFCMTokenIfAuthenticated(token: fcmToken)
                } catch {
                    print("Error storing FCM token: \(error)")
                }
            }
        } else {
            // 2) If no user is logged in yet, store it for later in UserDefaults (optional).
            UserDefaults.standard.set(fcmToken, forKey: "pendingFCMToken")
        }
    }
    
    func saveFCMTokenToFirestore(_ fcmToken: String) {
        // Ensure the user is authenticated
       guard let uid = Auth.auth().currentUser?.uid
        else {
            print("User is not authenticated. Cannot save FCM token.")
            return
        }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.setData(["fcmToken": fcmToken], merge: true) { error in
            if let error = error {
                print("Error saving FCM token to Firestore: \(error.localizedDescription)")
            } else {
                print("FCM token successfully saved to Firestore")
            }
        }
    }
}

@main
struct MovieClubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var dataManager: DataManager? = nil
    @State var notifManager: NotificationManager? = nil
    @State var versionManager: VersionManager? = nil
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showSplash {
                    if let dataManager, let notifManager {
                        HomeView()
                            .environment(dataManager)
                            .environment(notifManager)
                            .environment(versionManager)
                            .animation(.easeInOut(duration: 0.8), value: showSplash)
                    }
                } else {
                    SplashScreenView()
                        .onAppear {
                            // Initialize managers while splash is showing
                            dataManager = DataManager()
                            notifManager = NotificationManager()
                            versionManager = VersionManager()
                            Task {
                                try? await Task.sleep(for: .seconds(2.5))
                                // Use longer animation duration for smoother transition
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        }
                        .transition(.opacity)
                }
            }
            .colorScheme(.dark)
        }
    }
}
