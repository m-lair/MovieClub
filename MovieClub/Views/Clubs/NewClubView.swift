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
    @Binding var path: NavigationPath
    var filteredClubs: [MovieClub] {
        if searchText.isEmpty {
            clubList
        } else {
            clubList.filter { $0.name.localizedStandardContains(searchText)}
        }
    }
    var body: some View {
        VStack{
            List(filteredClubs){club in
                HStack{
                    Text("\(club.name)")
                        .font(.title)
                    Spacer()
                    Image(systemName: "person.fill")
                    Text(": \(club.numMembers)")
                    Button {
                        Task{
                            await data.joinClub(club: club)
                            data.userMovieClubs.append(club)
                            btnDisabled = true
                            dismiss()
                        }
                    } label: {
                        Text("Join")
                    }
                    .disabled(btnDisabled)
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
                    try await clubList = getClubList()
                } catch {
                    print("Error Retrieving Clubs")
                }
            }
        }
    }

    func getClubList() async throws -> [MovieClub]{
        var newList: [MovieClub] = []
        do{
            
            let snapshot = try? await data.movieClubCollection().getDocuments()
            let movieClubs = snapshot?.documents ?? []
            for document in movieClubs {
                let movieClub = try document.data(as: MovieClub.self)
                if await !data.userMovieClubs.contains(movieClub) {
                    newList.append(movieClub)
                }
                
            }
        }catch{
            print("Error decoding movie club: \(error)")
        }
        return newList
    }
}
    


        
    
    // thinking of using a plus button on the clubs view to bring up this page
    // after that the user should be presented with a search bar to search the name of the club
    // if the user wishes to create their own then lets make the top right of this search view a Create button
    // when button is clicked it will take the user to the form to create one from scratch
