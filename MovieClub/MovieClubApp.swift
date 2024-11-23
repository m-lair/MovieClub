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
import FirebaseFunctions
import AuthenticationServices
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        Analytics.setAnalyticsCollectionEnabled(true)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            Messaging.messaging().apnsToken = deviceToken
        }
    // Handle notification in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    // Handle notification when user interacts with it
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        _ = response.notification.request.content.userInfo
        // Handle navigation or other actions based on the notification's payload
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            //print("fcm: \(fcm)")
            saveFCMTokenToFirestore(fcm)
        }
    }
    
    func saveFCMTokenToFirestore(_ fcmToken: String) {
        guard Auth.auth().currentUser != nil else { return }
        let updateFCM: Callable<String, Bool?> = Functions.functions().httpsCallable("users-updateUserFCMToken")
        Task {
            let result = try await updateFCM(fcmToken)
        }
    }
}

@main
struct MovieClubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var dataManager: DataManager
    @State var notifManager: NotificationManager
    @State var isLoading: Bool = true
    init() {
        configureFirebase()
        dataManager = DataManager()
        notifManager = NotificationManager()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    WaveLoadingView()
                } else if dataManager.authCurrentUser != nil {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .task {
                await dataManager.checkUserAuthentication()
                isLoading = false
            }
        }
        .environment(dataManager)
        .environment(notifManager)
    }
}
