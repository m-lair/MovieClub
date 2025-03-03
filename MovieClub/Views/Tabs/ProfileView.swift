//
//  ProfileView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ProfileView: View {
    @Environment(DataManager.self) private var data: DataManager
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    let userId: String?
    @State var user: User?
    @State var imageStr: String? = ""
    var body: some View {
        VStack {
            // Profile Image
            if let imageUrl = user?.image, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
                .id(user?.image)
    
            } else {
                // Placeholder when no image is available
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
            }
            ProfileDisplayView(user: user)
        }
        .navigationTitle("Profile")
        .task {
            if let userId = userId {
                do {
                    user = try await data.fetchProfile(id: userId)
                } catch {
                    print("Error fetching profile: \(error)")
                }
            }
        }
    }
}
