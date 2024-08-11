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
    let club: MovieClub
    var body: some View {
        LazyVStack {
            Text("Coming Soon...")
                .font(.title)
            Divider()
            ForEach(comingSoon.indices, id: \.self) { index in
                HStack{
                    AsyncImage(url: URL(string: comingSoon[index].userAvi)) {
                        phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipped()
                                .clipShape(.circle)
                                .frame(width: 25, height: 25)
                        case .empty:
                            Image(systemName: "person.crop.circle.fill")
                        case .failure(_):
                            Image(systemName: "person.crop.circle.fill")
                        @unknown default:
                            Image(systemName: "person.crop.circle.fill")
                        }
                    }
                    Text("\(comingSoon[index].userName)")
                    Spacer()
                    
                    if let date = Calendar.current.date(byAdding: .weekOfYear, value: club.timeInterval * index, to: club.movieEndDate) {
                        Text("\(String(describing: date.formatted(date: .numeric, time: .omitted)))")
                            .font(.title3)
                            .foregroundStyle(.black)
                        
                        if comingSoon[index].id == data.currentUser?.id ?? "" {
                            NavigationLink(value: "EditMovies") {
                                Label("Edit Movies", systemImage: "pencil")
                                
                            }
                        }
                    }
                    
                }
                .padding()
                .frame(width: (screenWidth - 20), height: 25)
                .background(Color(.gray))
                .clipShape(.rect(cornerRadius: 20))
                
                
            }
            
        }
        .onAppear() {
            Task{
                await getUserData()
            }
        }
        Spacer()
    }
    func inrement() {
        self.i += 1
    }
        
    func getUserData() async {
        if let id = await data.currentClub?.id {
            do {
                let snapshot = try await data.movieClubCollection().document(id).collection("members").getDocuments()
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

