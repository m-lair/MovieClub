//
//  ClubEditView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/10/24.
//

import SwiftUI
import Foundation


struct ClubEditView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) var dismiss
    @State var errorShowing: Bool = false
    @State var errorMessage: String = ""
    
    @State var name = ""
    @State var description = ""
    @State var isPublic: Bool = false
    @State var timeInterval: Int = 0
    @State var ownerId: String = ""
    
    @Binding var movieClub: MovieClub
    
    var body: some View {
        VStack(spacing: 5){
            TextField(movieClub.name, text: $name)
            Divider()
            TextField(movieClub.desc ?? " ", text: $description)
            Divider()
            Toggle("Public", isOn: $isPublic)
            Divider()
            Picker("Week Interval", selection: $timeInterval) {
                ForEach(1..<5, id: \.self) { option in
                    Text("\(option)").tag(option)
                }
            }
            .pickerStyle(.segmented)
            Spacer()
            Button("Update") {
                Task {
                   try await submit()
                }
                dismiss()
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 10)
        }
        
        .alert(errorMessage, isPresented: $errorShowing) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            name = movieClub.name
            description = movieClub.desc ?? ""
            isPublic = movieClub.isPublic
            timeInterval = movieClub.timeInterval
            ownerId = movieClub.ownerId
        }
    }
    
    private func submit() async throws {
        guard let user = data.currentUser else {
            errorShowing = true
            errorMessage = "You must be logged in to update a club"
            return
        }
        guard !name.isEmpty else {
            errorShowing = true
            errorMessage = "Name cannot be empty"
            return
        }
        guard !description.isEmpty else {
            errorShowing = true
            errorMessage = "Description cannot be empty"
            return
        }
        guard timeInterval != 0 else {
            errorShowing = true
            errorMessage = "Time Interval cannot be empty"
            return
        }
        
        let updatedClub = MovieClub(id: movieClub.id, name: name, desc: description, ownerName: user.name, timeInterval: timeInterval, ownerId: ownerId, isPublic: isPublic)
        do {
            try await data.updateMovieClub(movieClub: updatedClub)
            // Update only the necessary properties
            movieClub.name = updatedClub.name
            movieClub.desc = updatedClub.desc
            movieClub.ownerName = updatedClub.ownerName
            movieClub.timeInterval = updatedClub.timeInterval
            movieClub.ownerId = updatedClub.ownerId
            movieClub.isPublic = updatedClub.isPublic
            
            if let index = data.userClubs.firstIndex(where: { $0.id == movieClub.id }) {
                print("updated club \(data.userClubs[index].id)")
                data.userClubs[index] = movieClub
            }
            
        } catch {
            errorShowing = true
            errorMessage = "Error updating club: \(error)"
        }
    }
}
