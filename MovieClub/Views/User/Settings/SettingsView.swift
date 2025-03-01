//
//  SettingsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/10/24.
//


import SwiftUI

struct SettingsView: View {
    @Environment(DataManager.self) var data
    @Environment(\.dismiss) var dismiss
    @State private var showingEditProfile = false
    var user: User? { data.currentUser }
    
    var body: some View {
        NavigationStack {
            if let user = data.currentUser {
                SettingsDivider()
                VStack(alignment: .leading) {
                    NavigationLink(destination: UserEditView()) {
                        HStack {
                            // Profile Image
                            if let imageUrl = user.image, let url = URL(string: imageUrl) {
                                CachedAsyncImage(url: url) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .padding(.leading)
                                .id(user.image)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .padding(.leading)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Edit Profile")
                                    .font(.caption)
                                    .fontWeight(.light)
                            }
                        }
                        Spacer()
                    }
                    
                    SettingsDivider()
                        .padding(.bottom)
                    
                    Label {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                    } icon: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.gray)
                    }
                    .font(.largeTitle)
                    .padding(.top)
                    .padding(.leading, 5)
                    
                    SettingsDivider()
                    
                    SettingsRowView(icon: "bell.fill", label: "Notifications", destination: NotifSettingsView())
                    
                    SettingsDivider()
                    
                    SettingsRowView(icon: "info.circle.fill", label: "About", destination: AboutView())
                    
                    SettingsDivider()
                    
                    SettingsRowView(icon: "accessibility.fill", label: "Accessibility", destination: AccessibilityView())
                    
                    SettingsDivider()
                }
                Spacer()
                
                Button {
                    guard let userId = user.id else { return }
                    Task {
                        try await data.deleteUserAccount(userId: userId)
                        data.authCurrentUser = nil
                    }
                } label: {
                    Text("Delete Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                .frame(maxWidth: UIScreen.main.bounds.width - 40)
            }
        }
        .onAppear {
            refreshUserData()
        }
        .toolbar {
            ToolbarItem {
                Button("Sign Out") {
                    data.signOut()
                }
                .foregroundStyle(.red)
            }
        }
        .toolbarRole(.editor)
    }
    
    private func refreshUserData() {
        Task {
            if let userId = data.currentUser?.id {
                if let updatedUser = try? await data.fetchProfile(id: userId) {
                    await MainActor.run {
                        data.currentUser = updatedUser
                    }
                }
            }
        }
    }
}

struct SettingsRowView<Destination: View>: View {
    let icon: String
    let label: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                Text(label)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .padding(.trailing)
            }
            .padding(.leading)
            .padding(.vertical, 8)
        }
    }
}

struct SettingsDivider: View {
    let color: Color = .gray
    let width: CGFloat = 1
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: width)
            .edgesIgnoringSafeArea(.horizontal)
            .opacity(0.5)
    }
}


struct NotifSettingsView: View { var body: some View { Text("Notifications Settings Screen") } }
struct ReferralDashboardView: View { var body: some View { Text("Referral Dashboard Screen") } }
struct AboutView: View { var body: some View { Text("About Screen") } }
struct AccessibilityView: View { var body: some View { Text("Accessibility Screen") } }
