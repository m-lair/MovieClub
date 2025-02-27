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
import FirebaseFunctions

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
            
            var fetchedNotifications: [Notification] = []
            for document in snapshot.documents {
                do {
                    let notif = try document.data(as: Notification.self)
                    fetchedNotifications.append(notif)
                } catch {
                    print("Failed to decode notification \(document.documentID): \(error.localizedDescription)")
                }
            }
    
            self.notifications = fetchedNotifications
        } catch {
            if let nsError = error as NSError? {
                print("Failed to fetch notifications: \(nsError.localizedDescription) (code: \(nsError.code))")
            } else {
                print("An unknown error occurred while fetching notifications: \(error)")
            }
        }
    }

    func deleteNotification(_ notification: Notification) async throws {
        guard let uid = Auth.auth().currentUser?.uid,
              let notificationId = notification.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid notification or user ID"])
        }
        
        let functions = Functions.functions()
        let data: [String: Any] = ["notificationId": notificationId]
        
        do {
            _ = try await functions.httpsCallable("deleteNotification").call(data)
            // Remove the notification from local array
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications.remove(at: index)
            }
        } catch {
            throw error
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

