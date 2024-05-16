//
//  CreateClubForm.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/14/24.
//

import SwiftUI

struct CreateClubForm: View {
    @Environment(DataManager.self) private var data: DataManager
    @State private var clubName = ""
    @State private var isPublic = false // Default to private
    @State private var selectedOwnerIndex = 0
    @State private var owners = ["User1"]
    var body: some View {
        Form {
            Section(header: Text("Club Information")) {
                TextField("Club Name", text: $clubName)
                Toggle("Public Club", isOn: $isPublic)
                
            }
        }
        // Add more sections for additional club information
        .navigationBarTitle("Add Movie Club")
        .navigationBarItems(trailing: Button("Save") {
            Task{
                // Call a method to save the club with the entered information
                
                let movieClub = MovieClub(id: generateUUID(), name: clubName,
                                          ownerName: data.currentUser?.name ?? "",
                                          ownerID: data.currentUser?.id ?? "",
                                          isPublic: isPublic)
                await saveClub(movieClub: movieClub)
            }
        })
    }
    
    private func saveClub(movieClub: MovieClub) async {
        Task{
            await data.createMovieClub(movieClub: movieClub)
        }
        
        
    }
    private func generateUUID() -> String {
        let id = UUID()
        return id.uuidString
    }
}

#Preview {
    CreateClubForm()
}
