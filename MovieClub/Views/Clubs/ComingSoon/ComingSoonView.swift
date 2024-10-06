//
//  RosterView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI
import FirebaseFirestore

struct ComingSoonView: View {
    @Environment(DataManager.self) var data: DataManager
    @State var i: Int = 0
    @State private var screenWidth = UIScreen.main.bounds.size.width
    @State var comingSoon: [Member] = []
    @State var imageUrl: String = ""
    let club: MovieClub
    var body: some View {
        VStack {
            Text("Coming Soon...")
                .font(.title)
            Divider()
            List {
                ForEach(comingSoon.indices, id: \.self) { index in
                    HStack{
                        ComingSoonRowView(member: comingSoon[index])
                        Spacer()
                        if let date = Calendar.current.date(byAdding: .weekOfYear, value: club.timeInterval * index, to: club.movieEndDate ?? Date()) {
                            Text("\(String(describing: date.formatted(date: .numeric, time: .omitted)))")
                                .font(.title3)
                                .foregroundStyle(.black)
                            
                            if comingSoon[index].id == data.currentUser?.id ?? "" {
                                NavigationLink(value: "EditMovies") {
                                    Label("Edit", systemImage: "pencil")
                                    
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(width: (screenWidth - 20), height: 30)
                .background(Color(.gray))
                .clipShape(.rect(cornerRadius: 20))
                
            }
        }
        .onAppear() {
            Task{
                await getUserData()
            }
        }
    }
    //populate coming soon list
    func getUserData() async {
        if let id = data.currentClub?.id {
            do {
                let snapshot = try await data.movieClubCollection().document(id).collection("members").order(by: "dateAdded", descending: false).getDocuments()
                let members = snapshot.documents.compactMap { member in
                    do {
                        return try member.data(as: Member.self)
                    }catch{
                        print("error getting members \(error)")
                        return nil
                    }
                }
                self.comingSoon = members
            }catch {
                print("couldnt get to club members")
            }
        }
    }
}

