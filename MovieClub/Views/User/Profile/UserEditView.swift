//
//  UserEditView.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/24/24.
//

import SwiftUI
//change editMode to only be used on lists
//will need a dedicated edit/save
//do it like instagram

struct UserEditView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Local States for Profile Fields
    @State private var name: String = ""
    @State private var bio: String = ""
    
    // MARK: - Error Handling
    @State private var errorShowing: Bool = false
    @State private var errorMessage: String = ""
    
    // Original values (to detect changes)
    @State private var originalName: String = ""
    @State private var originalBio: String = ""
    @State private var originalPhotoURL: String = ""
    
    // MARK: - Stock Images
    @State private var stockImages: [URL] = []
    @State private var selectedStockURL: URL? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.25), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 1) Profile Details Form
                    ProfileDetailsForm(
                        name: $name,
                        bio: $bio
                    )
                    .frame(maxHeight: 150)
                    
                    // 2) Stock Avatar Picker
                    StockAvatarPicker(
                        stockImages: stockImages,
                        selectedStockURL: $selectedStockURL
                    )
                    
                    Spacer()
                    // Action Buttons
                    ActionButtons(
                        onCancel: { dismiss() },
                        onSave: { saveProfileChanges() }
                    )
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadExistingProfile()
                // Fetch stock avatar URLs
                stockImages = await data.fetchStockProfilePictureURLs()
                
                // If current photoURL is one of the stock images, highlight it
                if let currentURL = URL(string: originalPhotoURL),
                   stockImages.contains(currentURL) {
                    selectedStockURL = currentURL
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadExistingProfile() async {
        if let existingUser = data.currentUser {
            // Store originals for comparison
            originalName = existingUser.name
            originalBio = existingUser.bio ?? ""
            originalPhotoURL = existingUser.image ?? ""
            
            // Fill text fields
            name = originalName
            bio = originalBio
        }
    }
    
    private func hasProfileChanged() -> Bool {
        return (name != originalName || bio != originalBio || 
                (selectedStockURL?.absoluteString != originalPhotoURL))
    }
    
    private func saveProfileChanges() {
        Task {
            if name.isEmpty { return }
            guard var userUpdates = data.currentUser else { return }
            
            do {
                if hasProfileChanged() {
                    userUpdates.name = name
                    userUpdates.bio = bio
                    
                    // Update photo URL if changed
                    if let chosenURL = selectedStockURL,
                       chosenURL.absoluteString != originalPhotoURL {
                        print("setting image to \(chosenURL.absoluteString)")
                        userUpdates.image = chosenURL.absoluteString
                    }
                    
                    try await data.updateUserDetails(user: userUpdates)
                    data.currentUser = userUpdates
                    
                }
                dismiss()
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                errorShowing = true
            }
        }
    }
}

// MARK: - Subview #1: Profile Details Form
struct ProfileDetailsForm: View {
    @Binding var name: String
    @Binding var bio: String
    
    var body: some View {
        Form {
            Section("Profile Details") {
                TextField("Name", text: $name)
                
                TextField("Bio", text: $bio, axis: .vertical)
                    .lineLimit(3)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
            }
        }
        .formStyle(.grouped)
        .cornerRadius(20)
    }
}

// MARK: - Subview #2: Action Buttons
fileprivate struct ActionButtons: View {
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(role: .cancel) {
                onCancel()
            } label: {
                Text("Cancel")
            }
            .padding(.bottom)
            .buttonStyle(.bordered)
            
            Button("Save") {
                onSave()
            }
            .padding(.bottom)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }
}

// Add new StockAvatarPicker:
struct StockAvatarPicker: View {
    let stockImages: [URL]
    @Binding var selectedStockURL: URL?
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            // Title and subtitle
            VStack(spacing: 5) {
                Text("Choose an avatar")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 5)
            
            // Main selected avatar display
            ZStack(alignment: .topTrailing) {
                if let selectedURL = selectedStockURL {
                    AsyncImage(url: selectedURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 5)

                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 5)
                }
            }
            .padding(.bottom, 20)
            
            // Grid of avatar options
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(stockImages, id: \.self) { url in
                    Button(action: {
                        selectedStockURL = url
                    }) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    (selectedStockURL == url) ? Color.blue : Color.white,
                                    lineWidth: 3
                                )
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
