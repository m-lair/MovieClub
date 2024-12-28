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

    var body: some View {
        NavigationStack {
            if let user = data.currentUser {
               SettingsDivider()
                VStack(alignment: .leading) {
                    NavigationLink(destination: LoginInformationView()) {
                        HStack {
                            Circle()
                                .frame(width: 60, height: 60)
                                .padding(.leading)
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Edit Username, Email, and Password")
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
            }
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

struct LoginInformationView: View {
    @Environment(DataManager.self) var data
    @Environment(\.dismiss) var dismiss
    @State var error: Error? = nil
    @State var editing = false
    @State var name: String = ""
    @State var email: String = ""
    @State var bio: String = ""
    
    var body: some View {
        if let user = data.currentUser {
            VStack {
                //AviSelector()
                  //  .padding(.vertical)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Username")
                        .padding(5)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    TextField(text: $name, label: { Text(user.name).foregroundStyle(.white) })
                        .padding(.leading, 10)
                    Divider()
                    Text("Email")
                        .padding(5)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    TextField(text: $email, label: { Text(user.email).foregroundStyle(.white) })
                        .padding(.leading, 10)
                    
                }
                .padding(5)
                .frame(maxWidth: UIScreen.main.bounds.width - 40)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color(red: 29/255, green: 29/255, blue: 29/255)))
                
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
                
                Spacer()
            }
            .toolbar {
                if editing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            Task {
                                await submit()
                            }
                            dismiss()
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(error != nil), actions: {
                Button("OK") {
                    error = nil
                }
            }, message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            })
            .onChange(of: [name, email, bio]) {
                editing = true
                if name.isEmpty && email.isEmpty && bio.isEmpty {
                    editing = false
                }
            }
        }
    }
    
    func submit() async {
        guard let currentUser = data.currentUser else { return }
        
        // Start with the current values
        var updatedName = currentUser.name
        var updatedEmail = currentUser.email
        var updatedBio = currentUser.bio

        // Apply updates only if non-empty and different
        if !name.isEmpty, name != currentUser.name {
            updatedName = name
        }

        if !email.isEmpty, email != currentUser.email {
            updatedEmail = email
        }

        if !bio.isEmpty, bio != currentUser.bio {
            updatedBio = bio
        }

        // Check if anything changed by comparing fields
        let somethingChanged =
            (updatedName != currentUser.name) ||
            (updatedEmail != currentUser.email) ||
            (updatedBio != currentUser.bio)

        // Proceed only if there's an actual change
        if somethingChanged {
            do {
                // Create a new user instance with updated values
                let updatedUser = User(email: updatedEmail, bio: updatedBio, name: updatedName)
                
                // Perform the update
                try await data.updateUserDetails(user: updatedUser)
                
                // After a successful update, set currentUser to the updated instance
                // If currentUser is a class, you could also just update its properties
                // directly instead of creating a new instance:
                currentUser.email = updatedEmail
                currentUser.name = updatedName
                currentUser.bio = updatedBio

                // If desired, you can explicitly update `data.currentUser` as well:
                data.currentUser = currentUser
            } catch {
                self.error = error
            }
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
