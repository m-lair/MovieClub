//
//  UserSettingsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/9/24.
//

import SwiftUI

struct UserSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                SettingsSectionView(headerText: "Account", headerColor: .orange) {
                    SettingsRowView(icon: "person.circle", label: "Login Information")
                    SettingsRowView(icon: "house", label: "Addresses")
                    SettingsRowView(icon: "creditcard", label: "Payment Methods")
                    SettingsRowView(icon: "person.3", label: "Referral Dashboard")
                }
                
                SettingsSectionView(headerText: "Orders & Subscriptions", headerColor: .green) {
                    SettingsRowView(icon: "shippingbox", label: "Orders")
                    SettingsRowView(icon: "calendar", label: "Subscriptions")
                    SettingsRowView(icon: "arrowshape.turn.up.backward", label: "My Returns")
                }
                
                SettingsSectionView(headerText: "Settings", headerColor: .blue) {
                    SettingsRowView(icon: "bell", label: "Notifications")
                    SettingsRowView(icon: "location", label: "Region")
                    SettingsRowView(icon: "pawprint", label: "App Version")
                    SettingsRowView(icon: "arrow.down.circle", label: "Firmware Updates")
                    SettingsRowView(icon: "pencil", label: "Release Notes")
                    SettingsRowView(icon: "globe", label: "Measurement Units")
                }
                
                SettingsSectionView(headerText: "Support", headerColor: .red) {
                    // Add Support rows as needed
                }
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all)) // For dark mode style
    }
  
}


struct SettingsSectionView<Content: View>: View {
    let headerText: String
    let headerColor: Color
    let content: Content
    
    init(headerText: String, headerColor: Color, @ViewBuilder content: () -> Content) {
        self.headerText = headerText
        self.headerColor = headerColor
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(headerText)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(headerColor)
                .cornerRadius(10)
            
            VStack(spacing: 10) {
                content
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(.trailing, 10)
            Text(label)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(8)
    }
}
