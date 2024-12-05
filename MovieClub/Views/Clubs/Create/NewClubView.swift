import SwiftUI
import FirebaseFirestore

struct NewClubView: View {
    @Environment(DataManager.self) private var data: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @Binding var path: NavigationPath
    @State private var searchText: String = ""
    @State private var clubList: [MovieClub] = []
    
    var filteredClubs: [MovieClub] {
        clubList.filter { club in
            !data.userClubs.contains { $0.id == club.id } &&
            (searchText.isEmpty || club.name.localizedStandardContains(searchText)) && club.isPublic
        }
    }
    
    var body: some View {
        VStack {
            List(filteredClubs) { club in
                HStack {
                    Text(club.name)
                        .font(.title)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                        Text("\(club.numMembers ?? 0)")
                    }
                    Button("Join") {
                        Task {
                            try await data.joinClub(club: club)
                            dismiss()
                        }
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.bordered)
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
    //this method is getting clubs as nil because of the document id
    func getClubList() async throws -> [MovieClub] {
        let snapshot = try await data.movieClubCollection().whereField("isPublic", isEqualTo: "true").getDocuments()
        let clubList: [MovieClub] = try snapshot.documents.compactMap { document in
            
            var club = try document.data(as: MovieClub.self)
            club.id = document.documentID
            return club
        }
        return clubList
    }
}
