import SwiftUI
import FirebaseFirestore

struct NewClubView: View {
    @Environment(DataManager.self) private var data: DataManager
    @Environment(\.dismiss) private var dismiss

    @Binding var path: NavigationPath
    @State private var searchText = ""
    @State private var clubList: [MovieClub] = []
    @State private var isLoading = false

    var filteredClubs: [MovieClub] {
        clubList.filter { club in
            !data.userClubs.contains(where: { $0.id == club.id }) &&
            (searchText.isEmpty || club.name.localizedStandardContains(searchText))
        }
    }

    var body: some View {
        VStack {
            if isLoading {
                WaveLoadingView()
            } else {
                List {
                    ForEach(filteredClubs, id: \.id) { club in
                        MovieClubRowView(club: club) {
                            Task {
                                await joinClub(club)
                            }
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
                // Animate changes to the ForEach
                .animation(.easeInOut, value: filteredClubs)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Find or Create Club")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: ClubDetailsForm(navPath: $path)) {
                    Text("Create")
                }
            }
        }
        .task {
            await loadClubs()
        }
    }

    func loadClubs() async {
        do {
            
            let clubs = try await data.fetchAllPublicClubs()
            for clubId in clubs {
                guard let club = await data.fetchMovieClub(clubId: clubId) else { return }
                clubList.append(club)
            }
            
        } catch {
            print("Error retrieving clubs: \(error)")
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
}


struct MovieClubRowView: View {
    @Environment(DataManager.self) var data
    @State var club: MovieClub
    var joinAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
        .task {
            if let clubId = club.id {
                guard let loadingClub = await data.fetchMovieClub(clubId: clubId) else { return }
                //print("club fetched: \(loadingClub.name), id: \(loadingClub.id ?? "nil"), members: \(loadingClub.numMembers ?? 0), bannerUrl: \(loadingClub.bannerUrl ?? "nil")")
                self.club = loadingClub
            }
        }
    }
}
