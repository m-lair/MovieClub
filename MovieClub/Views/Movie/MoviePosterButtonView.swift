//
//  MoviePosterButtonView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/28/24.
//

import SwiftUI

struct MoviePosterButtonView: View {
    var i: Int?
    var member: Membership?
    var body: some View {
        VStack{
            if let member = member, let i = i {
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
                        } else {
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
            }else{
                NavigationLink(destination: AddMovieView(date: Date(), index: 0)) {
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
}
