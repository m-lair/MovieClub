//
//  ProfileView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ProfileView: View {
    @Environment(DataManager.self) private  var data: DataManager
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    let userId: String
    @State private var user: User?
    @State private var edit = false
    @State private var name = ""
    @State private var bio = ""
    var body: some View {
        VStack{
            AviSelector()
            ProfileDisplayView(user: user)
        }
        .navigationTitle("Profile")
        .task {
            do {
                print("in profile view")
                // Assuming DataManager has a method like this:
                if let fetchedUser = try await data.fetchProfile(id: userId) {
                    self.user = fetchedUser
                }
            } catch {
                print("Failed to fetch user: \(error.localizedDescription)")
            }
        }
    }
    
}
