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
        application.registerForRemoteNotifications()
        configureFirebase()
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
            //print("fcm: \(fcm)")
            saveFCMTokenToFirestore(fcm)
        }
    }
    
    func saveFCMTokenToFirestore(_ fcmToken: String) {
        // Ensure the user is authenticated
       /* guard let uid = Auth.auth().currentUser?.uid
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
        }*/
    }
}

@Observable
class AppState {
    var isLoading = true
    let authManager: AuthManager
    let dataManager: DataManager
    
    init() async throws {
        self.isLoading = true
        self.authManager = AuthManager()
        
        do {
            self.dataManager = try await DataManager()
        } catch {
            fatalError("Failed to initialize DataManager: \(error)")
        }
        
        self.isLoading = false
    }
}

@main
struct MovieClubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Use StateObject for the initial state container
    @StateObject private var stateContainer = StateContainer()
    
    init() {
        print("MovieClubApp initializing")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let appState = stateContainer.appState {
                    MainContentView(appState: appState)
                } else {
                    ProgressView("Initializing...")
                        .onAppear {
                            print("Showing loading view")
                            stateContainer.initializeAppState()
                        }
                }
            }
        }
    }
}

// State container to handle async initialization
@MainActor
@Observable class StateContainer: ObservableObject {
    var appState: AppState?
    
    func initializeAppState() {
        Task {
            do {
                self.appState = try await AppState()
                print("AppState initialized successfully")
            } catch {
                print("Error initializing AppState: \(error)")
            }
        }
    }
}
struct MainContentView: View {
    let appState: AppState
    @Bindable var authManager: AuthManager
    
    init(appState: AppState) {
        self.appState = appState
        self.authManager = appState.authManager
    }
    
    var body: some View {
        Group {
            if authManager.authCurrentUser != nil {
                let _ = print("User is logged in - showing content view")
                ContentView()
                    .environment(appState.authManager)
                    .environment(appState.dataManager)
                    .task {
                        do {
                            try await appState.dataManager.fetchUser()
                        } catch {
                            print("Error fetching user: \(error)")
                            authManager.authCurrentUser = nil
                        }
                    }
            } else {
                let _ = print("User is not logged in - showing login view")
                LoginView()
                    .environment(appState.authManager)
                    .environment(appState.dataManager)
            }
        }
    }
}


