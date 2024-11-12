//
//  CreateClubView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//
//

import SwiftUI
import FirebaseFirestore

struct NewClubView: View {
    @Environment(DataManager.self) private var data: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State var sheetShowing = false
    @Binding var path: NavigationPath
    @State var searchText: String = ""
    @State var searchBarShowing = false
    @State var clubList: [MovieClub] = []
    @State var btnDisabled: Bool = false
    var filteredClubs: [MovieClub] {
        guard !searchText.isEmpty else {
            return clubList
        }
        return clubList.filter { club in
            let isNameMatching = club.name.localizedStandardContains(searchText)
            let isNotInUserMovieClubs = !data.userClubs.contains { $0.id == club.id }
            
            return isNameMatching && isNotInUserMovieClubs
        }
    }
    var body: some View {
        VStack{
            List(filteredClubs, id: \.id){club in
                HStack{
                    Text("\(club.name)")
                        .font(.title)
                    Spacer()
                    Image(systemName: "person.fill")
                    Text("\(club.numMembers ?? 0)")
                    Button {
                        Task{
                            do {
                                try await data.joinClub(club: club)
                            } catch {
                                print("error: \(error)")
                            }
                            await data.fetchUserClubs()
                            dismiss()
                        }
                    } label: {
                        Text("Join")
                    }
                }
                /* NavigationLink(destination: ClubDetailView(movieClub: club, path: $path )) {
                 Text(club.name)
                 .font(.title)
                 }*/
            }
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ClubDetailsForm(navPath: $path)) {
                        Text("Create")
                    }
                }
            }
            .navigationTitle("Find or Create Club")
        }
        .onAppear(){
            Task{
                do{
                    //data.clearMoviesCache()
                    try await clubList = getClubList()
                } catch {
                    print("Error Retrieving Clubs")
                }
            }
        }
    }

    func getClubList() async throws -> [MovieClub] {
        let snapshot = try await data.movieClubCollection().getDocuments()
        do {
            var clubs: [MovieClub] = []
            for document in snapshot.documents {
                let club = try document.data(as: MovieClub.self)
                club.id = document.documentID
                clubs.append(club)
            }
            return clubs
        } catch {
            print("Error decoding movie club: \(error)")
            return []
        }
    }
}
