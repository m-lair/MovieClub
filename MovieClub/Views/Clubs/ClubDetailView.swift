import SwiftUI
import FirebaseFirestore

struct ClubDetailView: View {
    let tabs: [String] = ["Bullentin", "Now Showing", "Upcoming", "Archives"]
    
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.editMode) var editMode
    @Environment(\.dismiss) var dismiss
  
    @State var selectedTabIndex: Int = 1
    @Binding var navPath: NavigationPath
    
    @State var isLoading: Bool = true
    @State var club: MovieClub
    
    var body: some View {
        VStack {
            ClubTabView(tabs: tabs, selectedTabIndex: $selectedTabIndex)
            
            TabView(selection: $selectedTabIndex) {
                BulletinView()
                    .tag(0)
        
                NowShowingView()
                        .tag(1)
                
                ComingSoonView(startDate: club.movieEndDate, timeInterval: club.timeInterval)
                    .tag(2)
                
                ArchivesView()
                    .tag(3)
            }
            .refreshable {
                Task {
                    if !data.clubId.isEmpty {
                        try await data.fetchMovies(clubId: data.clubId)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
        }
        .toolbar {
            ClubToolbar(club: club) { updatedClub in
                self.club = updatedClub
                data.currentClub = updatedClub
            }
        }
        .task {
            data.currentClub = club
            await data.fetchUserClubs()
        }
        .onDisappear {
            data.currentClub = nil
            data.comments = []
            data.movies = []
            data.suggestions = []
        }
    }
}
