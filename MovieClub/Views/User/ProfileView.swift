//
//  ProfileView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ProfileView: View {
    @Environment(DataManager.self) var datamanager
    var body: some View {
        Group {
            if let imageUrl = datamanager.currentUser?.image, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                    } else if phase.error != nil {
                        Color.red
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                }
            } else {
                ProgressView()
                    .frame(width: 100, height: 100)
            }
        }
        .onAppear {
            Task {
               await datamanager.getProfileImage(id: datamanager.currentUser?.id ?? "")
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(DataManager())
}
