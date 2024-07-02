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
    @State var searchText = ""
    @State var searchBarShowing = true
    @State var clubList: [MovieClub] = []
    var filteredClubs: [MovieClub] {
        if searchText.isEmpty {
            clubList
        } else {
            clubList.filter { $0.name.localizedStandardContains(searchText)}
        }
    }
    var body: some View {
        
        NavigationStack{
            VStack{
                //search bar results view
                List(filteredClubs){club in
                    NavigationLink(destination: ClubDetailView(movieClub: club)) {
                        Text(club.name)
                            .font(.title)
                    }
                }
                
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            
                        }
                    }
            }
            .sheet(isPresented: $sheetShowing, content: {
                CreateClubForm()})
            .navigationTitle("Find or Create Club")
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing){
                    HStack{
                        Button{
                            sheetShowing.toggle()
                        }label:{
                            Text("Create")
                        }
                    }
                }
            }
        )}
        .searchable(text: $searchText, isPresented: $searchBarShowing)
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
    }
    
    func getClubList() async throws -> [MovieClub]{
        var newList: [MovieClub] = []
        do{
            let db = Firestore.firestore()
            let snapshot = try? await db.collection("movieclubs").getDocuments()
            let movieClubs = snapshot?.documents ?? []
            for document in movieClubs {
                let movieClub = try document.data(as: MovieClub.self)
                newList.append(movieClub)
                }
        }catch{
            print("Error decoding movie club: \(error)")
        }
        return newList
    }
    


        
    
    // thinking of using a plus button on the clubs view to bring up this page
    // after that the user should be presented with a search bar to search the name of the club
    // if the user wishes to create their own then lets make the top right of this search view a Create button
    // when button is clicked it will take the user to the form to create one from scratch
    
   


#Preview {
    NewClubView(clubList: [MovieClub(name: "Test Title 1", 
                                     created: Date(),
                                     numMembers: 3,
                                     description: "test club for people", 
                                     ownerName: "Duhmarcus",
                                     ownerID: "000123",
                                     isPublic: true),
                           MovieClub(name: "Test Title 2",
                                     created: Date(),
                                     numMembers: 20,
                                     description: "test club for people", 
                                     ownerName: "darius garius",
                                     ownerID: "1345",
                                     isPublic: true)])
                           
        .environment(DataManager())
}

