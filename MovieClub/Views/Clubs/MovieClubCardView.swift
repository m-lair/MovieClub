//
//  MovieClubCardView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct MovieClubCardView: View {
    let movieClub: MovieClub
    @State private var screenWidth = UIScreen.main.bounds.size.width
    var body: some View {
        ZStack{
            VStack{
                AsyncImage(url: URL(string: movieClub.bannerUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .padding(-20) /// expand the blur a bit to cover the edges
                            .clipped() /// prevent blur overflow
                            .frame(maxWidth: (screenWidth - 20))
                            .blur(radius: 1.5, opaque: true)
                            .mask(LinearGradient(stops:
                                                    [.init(color: .white, location: 0),
                                                     .init(color: .white, location: 0.85),
                                                     .init(color: .clear, location: 1.0),], startPoint: .top, endPoint: .bottom))
                    } else {
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(-20) /// expand the blur a bit to cover the edges
                            .clipped() /// prevent blur overflow
                            .frame(maxWidth: (screenWidth - 20))
                            .opacity(0.5)
                    }
                }
            }
            .frame(width: (screenWidth - 20), height: 185)
            .clipShape(.rect(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(.white, lineWidth: 2)
            )
            .shadow(radius: 8)
            
            VStack(alignment: .leading){
                cardText.padding(.horizontal)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: (screenWidth - 20), maxHeight: 185, alignment: .bottomLeading)
            
        }
        
    }
    var cardText: some View {
        
        VStack(alignment: .leading){
            if !movieClub.name.isEmpty{
                Text(movieClub.name)
                    .font(.title)
                Text("Movie: \(movieClub.numMovies)")
                Text("Members: \(movieClub.numMembers)")
                    // You can add more information about the movie club here
                
            }
            
        }
    }
    
}
