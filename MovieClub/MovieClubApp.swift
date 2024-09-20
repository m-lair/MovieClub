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
import FirebaseFirestoreSwift
import AuthenticationServices
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAnalytics



class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                  UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: {_, _ in })
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
            print("fcm: \(fcm)")
            saveFCMTokenToFirestore(fcm)
        }
    }
    
    func saveFCMTokenToFirestore(_ fcmToken: String) {
        // Ensure the user is authenticated
        guard let uid = Auth.auth().currentUser?.uid else {
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
    @State private var notifmanager = NotificationManager()
    @State private var datamanager = DataManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(datamanager)
                .environment(notifmanager)
        }
        
    }
}
