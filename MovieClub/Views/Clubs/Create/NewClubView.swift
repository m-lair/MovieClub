import SwiftUI
import FirebaseFirestore

struct NewClubView: View {
    @Environment(DataManager.self) private var data: DataManager
    @Environment(\.dismiss) private var dismiss

    @Binding var path: NavigationPath
    @State private var searchText: String = ""
    @State private var clubList: [MovieClub] = []
    @State private var isLoading: Bool = false

    var filteredClubs: [MovieClub] {
        clubList.filter { club in
            !data.userClubs.contains { $0.id == club.id } &&
            (searchText.isEmpty || club.name.localizedStandardContains(searchText))
        }
    }

    var body: some View {
        VStack {
            List(filteredClubs) { club in
                MovieClubRowView(club: club) {
                    Task {
                        isLoading = true
                        defer { isLoading = false }
                        if let clubId = club.id {
                            try await data.joinClub(club: club)
                            if let newClub = await data.fetchMovieClub(clubId: clubId) {
                                data.userClubs.append(newClub)
                            }
                        }
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Find or Create Club")
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ClubDetailsForm(navPath: $path)) {
                        Text("Create")
                    }
                }
            }
        }
        .onAppear {
            Task {
                do {
                    clubList = try await getClubList()
                } catch {
                    print("Error retrieving clubs: \(error)")
                }
            }
        }
    }

    func getClubList() async throws -> [MovieClub] {
        let snapshot = try await data.movieClubCollection()
            .whereField("isPublic", isEqualTo: "true")
            .getDocuments()
        let clubList: [MovieClub] = try snapshot.documents.compactMap { document in
            var club = try document.data(as: MovieClub.self)
            club.id = document.documentID
            return club
        }
        return clubList
    }
}


struct MovieClubRowView: View {
    @Environment(DataManager.self) var data
    @State var club: MovieClub
    var joinAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Club banner image or a placeholder if none exists.
            if let bannerUrl = club.bannerUrl, let url = URL(string: bannerUrl) {
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
        .task {
            Task {
                if let clubId = club.id {
                    if let loadedClub = await data.fetchMovieClub(clubId: clubId) {
                        self.club = loadedClub
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
