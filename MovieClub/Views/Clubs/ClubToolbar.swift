//
//  ClubToolbar.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/11/24.
//
import Foundation
import SwiftUI

struct ClubToolbar: View {
    @Environment(DataManager.self) var data
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    @Binding var club: MovieClub

    
    var body: some View {
        Menu {
            Button {
                openURL(URL(string: "https://github.com/mney33/MovieClubReporting/issues/new/choose")!)
            } label: {
                Label("Report A Problem", systemImage: "exclamationmark.octagon")
            }
            if data.authCurrentUser?.uid == club.ownerId {
                NavigationLink {
                    ClubEditView(movieClub: $club)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            Button {
                Task {
                    do {
                        try await data.leaveClub(club: club)
                        data.userClubs.removeAll(where: { $0.id == club.id })
                    } catch {
                        print("Error leaving club: \(error)")
                    }
                    dismiss()
                }
            } label: {
                Label("Leave Club", systemImage: "trash")
            }
            .foregroundStyle(.red)
            
        } label: {
            Label("Menu", systemImage: "gearshape.fill")
        }
    }
}
