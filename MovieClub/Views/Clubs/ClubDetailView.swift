//
//  ClubDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI
import FirebaseFirestore

struct ClubDetailView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) var dismiss
    @Binding var navPath: NavigationPath
    
    @State var isLoading: Bool = true
    let club: MovieClub
    @State var isPresentingEditView = false
    var body: some View {
        ZStack{
            if isLoading {
                ProgressView()
            } else {
                BlurredBackgroundView(urlString: data.poster)
                VStack {
                    HeaderView(movieClub: club)
                    if let movie = data.movie {
                        NowPlayingView(movie: movie, club: club)
                    }
                }
                .padding()
                Spacer()
            }
        }
        .toolbar{
            if data.currentClub?.ownerId == data.currentUser?.id ?? "" {
                Menu {
                    Button {
                        // Do Nothing
                    } label: {
                        Label("Report A Problem", systemImage: "exclamationmark.octagon")
                    }
                    Button {
                        isPresentingEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        Task{
                            dismiss()
                        }
                    } label: {
                        Label("Leave Club", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                    
                } label: {
                    Label("Menu", systemImage: "ellipsis")
                }
            } else {
                Menu {
                    Button {
                        Task{
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
        .sheet(isPresented: $isPresentingEditView) {
            ClubDetailsForm(navPath: $navPath)
        }
        .task {
            await loadClub()
        }
    }
    private func loadClub() async {
        isLoading = true
        do {
            try await data.fetchClubDetails(club: club)
            isLoading = false
        } catch {
            print("Error fetching club details: \(error)")
        }
        
    }
}

/*
#Preview {
    ClubDetailView(movieClub: MovieClub.TestData[0])
        .environment(DataManager())
}
*/
