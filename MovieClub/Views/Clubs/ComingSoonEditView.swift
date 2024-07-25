//
//  ComingSoonEditView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/24/24.
//

import SwiftUI

struct ComingSoonEditView: View {
    @Environment(DataManager.self) var data: DataManager
    let userID: String
    @State var showSheet: Bool = false
    @State var index: Int = 0
    var body: some View {
        VStack {
            if let member = data.queue {
                HStack{
                    Label(member.clubName, systemImage: "house")
                    if let date = member.movieDate {
                        Label(String(date.formatted(date: .abbreviated, time: .omitted)), systemImage: "calendar")
                    }
                }
                .padding(.top)
                .font(.title)
                Label("Movie Queue", systemImage: "list.and.film")
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0..<3) { i in
                            VStack {
                                Text("\(member.queue[i].title)")
                                    .font(.title)
                                let url = URL(string: member.queue[i].poster ?? "")
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        NavigationLink(destination: AddMovieView(date: member.movieDate!, index: i)) {
                                            image
                                                .resizable()
                                                .frame(width: 200, height: 350)
                                                .background(Color.gray)
                                                .cornerRadius(10)
                                                .padding()
                                        }
                                    }else {
                                        NavigationLink(destination: AddMovieView(date: member.movieDate!, index: i)) {
                                            VStack {
                                                Spacer()
                                                Text("?")
                                                    .font(.system(size: 200))
                                                    .foregroundColor(.white)
                                                    .shadow(radius: 10)
                                                
                                            }
                                        }
                                        .frame(width: 100, height: 150)
                                        .background(Color.gray)
                                        .scaledToFit()
                                        .cornerRadius(10)
                                        .padding()
                                    }
                                }
                                
                            }
                            .navigationTitle("Select Movie")
                        }
                        .padding(.top)
                    }
                    
                }
            }
        }
        .onAppear(){
            Task{
                
                await data.loadQueue()
            }
        }
    }
    private func handleTap(index: Int) {
        self.showSheet = true
        self.index = index
    }
}

///-club
/// -members
///     -userID
///     -username
///     -selector
///     -movieDate



///-user
/// -membership
///     -clubName
///     -clubID
///     -queue
///     -movieDate
///
///
///
