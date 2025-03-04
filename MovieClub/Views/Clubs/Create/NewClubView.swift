import SwiftUI
import FirebaseFirestore

struct NewClubView: View {
    @Environment(DataManager.self) private var data: DataManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var path: NavigationPath
    @State private var searchText = ""
    @State private var clubList: [MovieClub] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    @State private var selectedClub: MovieClub? = nil
    @State private var showJoinConfirmation = false
    @State private var hasAppeared = false
    
    // Animation states
    @State private var rowOffsets: [CGFloat] = []
    @State private var rowOpacities: [Double] = []
    @State private var headerOpacity: Double = 0
    @State private var searchBarOffset: CGFloat = -50

    var filteredClubs: [MovieClub] {
        clubList.filter { club in
            !data.userClubs.contains(where: { $0.id == club.id }) &&
            (searchText.isEmpty || club.name.localizedStandardContains(searchText))
        }
    }

    var body: some View {
        ZStack {
            // Background color - solid black
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar with animation
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search clubs", text: $searchText)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                )
                .padding(.horizontal)
                .padding(.bottom, 16)
                .offset(y: searchBarOffset)
                .opacity(headerOpacity)
                
                if isLoading {
                    Spacer()
                    WaveLoadingView()
                        .frame(width: 60, height: 60)
                    Text("Finding clubs...")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    Spacer()
                } else if filteredClubs.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Empty state illustration
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "film")
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 8)
                        
                        Text(searchText.isEmpty ? "No public clubs available" : "No clubs match your search")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Create your own club to start watching movies with friends")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showCreateSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Your Own Club")
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                    .opacity(headerOpacity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("Clubs")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(filteredClubs.count) clubs")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            .opacity(headerOpacity)
                            
                            // Club list
                            ForEach(Array(filteredClubs.enumerated()), id: \.element.id) { index, club in
                                MovieClubRowView(club: club) {
                                    selectedClub = club
                                    showJoinConfirmation = true
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                                .offset(y: index < rowOffsets.count ? rowOffsets[index] : 50)
                                .opacity(index < rowOpacities.count ? rowOpacities[index] : 0)
                            }
                            
                            // Bottom padding
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Text("Create")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationTitle("Find or Create Club")
        .sheet(isPresented: $showCreateSheet) {
            ClubDetailsForm(navPath: $path)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Join \(selectedClub?.name ?? "Club")?", isPresented: $showJoinConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                if let club = selectedClub {
                    Task {
                        await joinClub(club)
                    }
                }
            }
        } message: {
            Text("You'll be added to this club and can start participating right away.")
        }
        .task {
            await loadClubs()
        }
        .onAppear {
            if !hasAppeared {
                // Animate UI elements when view appears
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    headerOpacity = 1
                    searchBarOffset = 0
                }
                hasAppeared = true
            }
        }
    }

    func loadClubs() async {
        do {
            let clubs = try await data.fetchAllPublicClubs()
            print("Fetched \(clubs.count) public clubs")
            
            for clubId in clubs {
                if clubList.contains(where: { $0.id == clubId }) { continue }
                guard let club = await data.fetchMovieClub(clubId: clubId) else { continue }
                
                // Debug print to check movie count
                print("Club \(club.name) has \(club.movies.count) movies")
                
                clubList.append(club)
            }
            
            // If no clubs were loaded, create sample data for testing
            if clubList.isEmpty {
                print("No clubs found, adding sample data for testing")
                // This is just for testing - remove in production
                let sampleClub1 = MovieClub(
                    id: "sample1",
                    name: "Sample Club 1",
                    desc: "This is a sample club for testing",
                    ownerName: "Test User",
                    timeInterval: 2,
                    ownerId: "testuser",
                    isPublic: true,
                    bannerUrl: nil
                )
                
                let sampleClub2 = MovieClub(
                    id: "sample2",
                    name: "Sample Club 2",
                    desc: "Another sample club for testing",
                    ownerName: "Test User",
                    timeInterval: 2,
                    ownerId: "testuser",
                    isPublic: true,
                    bannerUrl: nil
                )
                
                clubList.append(sampleClub1)
                clubList.append(sampleClub2)
            }
            
            // Initialize animation arrays
            rowOffsets = Array(repeating: 50, count: clubList.count)
            rowOpacities = Array(repeating: 0, count: clubList.count)
            
            // Animate rows with a slight delay
            animateRowsAppearance()
            
        } catch {
            print("Error retrieving clubs: \(error)")
        }
        
        isLoading = false
    }
    
    // Animation function for staggered row appearance
    private func animateRowsAppearance() {
        // Animate rows with staggered timing
        for i in 0..<rowOffsets.count {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.08)) {
                rowOffsets[i] = 0
                rowOpacities[i] = 1
            }
        }
    }

    func joinClub(_ club: MovieClub) async {
        do {
            isLoading = true
            // Join logic
            try await data.joinClub(club: club)
            // Re-fetch or locally update userClubs
            if let clubId = club.id,
               let newClub = await data.fetchMovieClub(clubId: clubId) {
                data.userClubs.append(newClub)
            }
        } catch {
            print("Error joining club: \(error)")
        }
        isLoading = false
        dismiss()
    }
    
    // Custom button style with scale animation
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
}

struct MovieClubRowView: View {
    @Environment(DataManager.self) var data
    @State var club: MovieClub
    var featuredMovie: Movie? {
        club.movies.first
    }
    
    var joinAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Check if the bannerUrl is valid.
            if let bannerUrl = club.bannerUrl,
               let url = URL(string: bannerUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                         .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(club.name)
                    .font(.headline)
                    .lineLimit(1)
                if let desc = club.desc {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if let movie = featuredMovie {
                    Text("Now showing: \(movie.title)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.secondary)
                    Text("\(club.numMembers ?? 0) Members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: joinAction) {
                Text("Join")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
        )
        .task {
            if let clubId = club.id {
                guard let loadingClub = await data.fetchMovieClub(clubId: clubId) else { return }
                self.club = loadingClub
            }
        }
    }
}
