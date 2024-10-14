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
    @Environment(\.editMode) var editMode
    @Environment(\.dismiss) var dismiss
    @Binding var navPath: NavigationPath
    
    @State var isLoading: Bool = true
    let club: MovieClub
    
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
                .toolbar {
                    ClubToolbar(club: club)
                }
            }
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
