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
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                )
                .padding(.horizontal)
                .padding(.bottom, 12)
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
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
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
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(filteredClubs.count) clubs")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                            .opacity(headerOpacity)
                            
                            // Club list with consistent spacing
                            ForEach(Array(filteredClubs.enumerated()), id: \.element.id) { index, club in
                                MovieClubRowView(club: club) {
                                    selectedClub = club
                                    showJoinConfirmation = true
                                }
                                .padding(.horizontal, 12)
                                .padding(.bottom, 10)
                                .offset(y: index < rowOffsets.count ? rowOffsets[index] : 50)
                                .opacity(index < rowOpacities.count ? rowOpacities[index] : 0)
                            }
                            
                            // Bottom padding
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.top, 12)
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
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
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
            // Step 1: Fetch all public club IDs
            let clubIds = try await data.fetchAllPublicClubs()
            print("Fetched \(clubIds.count) public clubs")
            
            if clubIds.isEmpty {
                isLoading = false
                return
            }
            
            // Step 2: Create a task group to fetch basic club info in parallel
            await withTaskGroup(of: MovieClub?.self) { group in
                for clubId in clubIds {
                    // Skip if we already have this club
                    if clubList.contains(where: { $0.id == clubId }) { continue }
                    
                    group.addTask {
                        // Fetch basic club info without TMDB data
                        return await self.fetchBasicClubInfo(clubId: clubId)
                    }
                }
                
                // Process results as they come in
                for await club in group {
                    if let club = club {
                        // Add to our list immediately so it shows up in the UI
                        clubList.append(club)
                        
                        // Update animation arrays
                        rowOffsets.append(50)
                        rowOpacities.append(0)
                        
                        // Animate the new row
                        let index = clubList.count - 1
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            rowOffsets[index] = 0
                            rowOpacities[index] = 1
                        }
                        
                        // Step 3: Fetch TMDB data asynchronously
                        Task {
                            await self.enrichClubWithTMDBData(club)
                        }
                    }
                }
            }
            
        } catch {
            print("Error retrieving clubs: \(error)")
        }
        
        isLoading = false
    }
    
    // Helper function to fetch basic club info without TMDB data
    private func fetchBasicClubInfo(clubId: String) async -> MovieClub? {
        do {
            // Get the club document
            guard let snapshot = try? await data.movieClubCollection().document(clubId).getDocument() else {
                print("Failed to fetch club document for ID: \(clubId)")
                return nil
            }
            
            // Parse basic club info
            var club = try snapshot.data(as: MovieClub.self)
            club.id = snapshot.documentID
            
            // Get member count
            let membersSnapshot = try await data.movieClubCollection()
                .document(clubId)
                .collection("members")
                .getDocuments()
            club.numMembers = membersSnapshot.documents.count
            
            // Get active movie (but don't fetch TMDB data yet)
            let moviesSnapshot = try await data.movieClubCollection()
                .document(clubId)
                .collection("movies")
                .whereField("status", isEqualTo: "active")
                .order(by: "createdAt", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if let document = moviesSnapshot.documents.first {
                var movie = try document.data(as: Movie.self)
                movie.id = document.documentID
                club.movies = [movie]
        
            } else {
                // No active movie found
                club.movies = []
                print("No active movie found for club: \(club.name)")
            }
            
            return club
        } catch {
            print("Error fetching basic club info for \(clubId): \(error)")
            return nil
        }
    }
    
    // Helper function to enrich a club with TMDB data
    private func enrichClubWithTMDBData(_ club: MovieClub) async {
        guard let clubId = club.id, let movie = club.movies.first else {
            print("Missing required data for TMDB fetch: clubId=\(club.id ?? "nil"), movie=\(club.movies.isEmpty ? "empty" : "exists"), imdbId=\(club.movies.first?.imdbId ?? "nil")")
            return
        }
        
        do {
            // Fetch TMDB data
            if let apiMovie = try await data.tmdb.fetchMovieDetails(movie.imdbId) {
                // Find the club in our list and update it
                if let index = clubList.firstIndex(where: { $0.id == clubId }) {
                    clubList[index].movies[0].apiData = apiMovie
                    clubList[index].bannerUrl = movie.poster
                }
            }
        } catch {
            print("Error fetching TMDB data for club \(clubId): \(error)")
        }
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
        HStack(spacing: 12) {
            // Club image
            clubImageView
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .id(club.id ?? UUID().uuidString)
            
            // Club details
            VStack(alignment: .leading, spacing: 4) {
                Text(club.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let desc = club.desc {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Current movie
                if let movie = featuredMovie {
                    HStack(spacing: 4) {
                        Image(systemName: "film")
                            .foregroundStyle(.gray)
                        
                        Text(movie.title.isEmpty ? "Loading movie..." : movie.title)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .id("\(club.id ?? "")-title")
                    }
                    .lineLimit(1)
                }
                
                // Member count
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(club.numMembers ?? 0) Members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            // Join button
            Button(action: joinAction) {
                Text("Join")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .sensoryFeedback(.impact, trigger: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
        )
    }
    
    // Extract club image view for cleaner code
    private var clubImageView: some View {
        Group {
            if let bannerUrl = club.bannerUrl,
               !bannerUrl.isEmpty,
               let url = URL(string: bannerUrl) {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.3)
            
            Image(systemName: "film")
                .font(.system(size: 24, weight: .regular, design: .default))
                .foregroundColor(.gray)
        }
    }
}
