//
//  NotificationManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/17/24.
//

import Foundation
import UserNotifications
import Observation

@Observable
class NotificationManager{
    private var hasPermission = false
    
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

