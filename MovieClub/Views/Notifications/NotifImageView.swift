//
//  NotifImageView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/23/24.
//

import Foundation
import SwiftUI

struct NotificationImageView: View {
    let type: NotificationType
    
    var body: some View {
        ZStack {
            // Profile picture (currently just a placeholder)
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 40, height: 40)
            
            // Notification icon with colored background
            Circle()
                .fill(type.iconColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: type.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                )
                .offset(x: 18, y: 18) // Offset to bottom-right of the profile circle
        }
    }
}

