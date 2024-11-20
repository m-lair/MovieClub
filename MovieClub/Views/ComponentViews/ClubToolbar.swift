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
    @Environment(\.dismiss) var dismiss
    let club: MovieClub
    var onUpdate: ((MovieClub) -> Void)?
    
    var body: some View {
        Menu {
            Button {
                // Report a problem action
            } label: {
                Label("Report A Problem", systemImage: "exclamationmark.octagon")
            }
            
            NavigationLink {
                ClubEditView(movieClub: club) { updatedClub in
                    data.currentClub = updatedClub
                    onUpdate?(updatedClub)
                }
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                Task {
                    do {
                        try await data.leaveClub(club: club)
                    } catch {
                        print("Error leaving club: \(error)")
                    }
                    await data.fetchUserClubs()
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

