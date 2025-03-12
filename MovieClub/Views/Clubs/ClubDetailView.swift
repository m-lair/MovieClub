import SwiftUI
import FirebaseFirestore

struct ClubDetailView: View {
    let tabs: [String] = ["About", "Now Showing", "Upcoming", "Archives"]
    
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
                ClubAboutView()
                    .tag(0)
        
                NowShowingView()
                    .tag(1)
                    .id("now-showing-\(club.movies.first?.id ?? "unknown")")
                    .transition(.opacity)
                
                ComingSoonView(startDate: club.movieEndDate, timeInterval: club.timeInterval)
                    .tag(2)
                
                ArchivesView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: club.movies.first?.id)
            
        }
        .toolbar {
            ClubToolbar(club: $club)
        }
        .task {
            data.currentClub = club
        }
        .onChange(of: club.movies) { oldMovies, newMovies in
            // Update data.currentClub when club.movies changes
            data.currentClub = club
        }
        .onDisappear {
            data.currentClub = nil
            data.comments = []
            data.movies = []
            data.suggestions = []
        }
        .navigationTitle(club.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
