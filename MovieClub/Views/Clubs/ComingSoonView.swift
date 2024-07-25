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
    @State private var screenWidth = UIScreen.main.bounds.size.width
    @State var comingSoon: [Member] = []
    var body: some View {
        LazyVStack {
            ForEach(comingSoon) { member in
                HStack{
                    AsyncImage(url: URL(string: member.userAvi)) {
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
                    Text("\(member.userName)")
                    Spacer()
                    Text("Date \(String(describing: member.movieDate?.formatted(date: .numeric, time: .omitted)))")
                        .font(.title3)
                        .foregroundStyle(.black)
                    if member.id == data.currentUser?.id ?? "" {
                        NavigationLink(value: "EditMovies") {
                            Label("Edit Movies", systemImage: "pencil")
                        }
                    }
                }
                .frame(width: (screenWidth - 20), height: 100)
                .clipped()
                .clipShape(.rect(cornerRadius: 10))
                .backgroundStyle(.gray)
               
            }
        }
        .onAppear() {
            Task{
                await getUserData()
            }
        }
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

