//
//  ClubDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI
import FirebaseFirestore



struct ClubDetailView: View {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    let tabs: [String] = ["Bullentin", "Now Showing", "Upcoming", "Archives"]
    
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.editMode) var editMode
    @Environment(\.dismiss) var dismiss
  
    @State var selectedTabIndex: Int = 1
    @Binding var navPath: NavigationPath
    
    @State var isLoading: Bool = true
    let club: MovieClub
    
    var body: some View {
        let testMovie: Movie = Movie(id: "0001", title: "The Matrix", startDate: startDate, endDate: endDate, userName: "duhmarcus", userId: "0001", authorAvi: "none")
        VStack {
            HeaderView(movieClub: club)
            ClubTabView(tabs: tabs, selectedTabIndex: $selectedTabIndex)
            
            TabView(selection: $selectedTabIndex) {
                BulletinView()
                    .tag(0)
                NowShowingView(movie: testMovie)
                    .tag(1)
                ComingSoonView(startDate: club.movieEndDate, timeInterval: club.timeInterval)
                    .tag(2)
                ArchivesView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
        }
        .toolbar {
            ClubToolbar(club: club)
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
