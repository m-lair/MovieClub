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
    @State var sheetShowing = false
    @Environment(\.dismiss) private var dismiss
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
                    Text("test club")
                        .font(.title)
                    Spacer()
                    Image(systemName: "person.fill")
                    Text(": \(club.numMembers)")
                    Button {
                        Task{
                            do {
                                print("clubId \(club.id)")
                                try await data.joinClub(club: club)
                            } catch {
                                print(error)
                            }
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
                    NavigationLink(value: "CreateForm"){
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
        do {
            let snapshot = try await data.movieClubCollection().getDocuments()
            return try snapshot.documents.map { document in
                try document.data(as: MovieClub.self)
            }
        } catch {
            print("Error decoding movie club: \(error)")
            return []
        }
    }
}
