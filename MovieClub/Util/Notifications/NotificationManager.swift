//
//  NotificationManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/17/24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import Observation

@Observable
class NotificationManager{
    private var hasPermission = false
    var notifications: [Notification] = []
    private let db = Firestore.firestore()
    
    init() {
        Task{
            await getAuthStatus()
        }
    }
    
    func request() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            hasPermission = granted
            if !granted {
                // Handle the case where the user denied permission
                print("User denied notification permissions.")
            }
        } catch {
            print("Failed to request authorization: \(error)")
        }
    }
    
    func fetchUserNotifications() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in.")
            return
        }
        
        do {
            let notificationsRef = db.collection("users").document(uid).collection("notifications")
            let snapshot = try await notificationsRef
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let fetchedNotifications = try snapshot.documents.compactMap { document in
                try document.data(as: Notification.self)
            }
            
            // Make sure to update UI-bound properties on the main thread.
            await MainActor.run {
                self.notifications = fetchedNotifications
            }
        } catch {
            if let nsError = error as NSError? {
                print("Failed to fetch notifications: \(nsError.localizedDescription) (code: \(nsError.code))")
            } else {
                print("An unknown error occurred while fetching notifications: \(error)")
            }
        }
    }

    
    func getAuthStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            hasPermission = true
        default:
            hasPermission = false
        }
    }
}

