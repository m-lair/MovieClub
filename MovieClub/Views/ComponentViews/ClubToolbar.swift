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
    
    var body: some View {
        Menu {
            if data.currentClub?.ownerId == data.currentUser?.id ?? "" {
                Button {
                    // Report a problem action
                } label: {
                    Label("Report A Problem", systemImage: "exclamationmark.octagon")
                }
        
                NavigationLink{
                        ClubEditView(movieClub: club)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                NavigationLink {
                    CreateSuggestionView()
                } label: {
                    Label("New Suggestion", systemImage: "plus")
                }
            }
            
            Button {
                Task {
                   dismiss()
                }
            } label: {
                Label("Leave Club", systemImage: "trash")
            }
            .foregroundStyle(.red)
            
        } label: {
            Label("Menu", systemImage: "ellipsis")
        }
    }

}

