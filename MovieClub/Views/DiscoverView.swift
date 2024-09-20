//
//  DiscoverView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct CardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Card Title")
                .font(.headline)
                .foregroundColor(.white)
            Text("This is some content that goes inside the card.")
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .random(in: 100..<250), idealHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct DiscoverView: View {
    var body: some View {
        VStack{
            VStack(alignment: .leading){
                Group{
                    Text("Trending Clubs")
                        .font(.title)
                        .padding(.leading)
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(0..<12){_ in
                                CardView()
                            }
                        }
                    }
                }
                .padding(.bottom)
                Group{
                    Text("Trending Movies")
                        .font(.title)
                        .padding(.leading)
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(0..<12){_ in
                                CardView()
                            }
                        }
                    }
                }
                .padding(.bottom)
                Group{
                    Text("News")
                        .font(.title)
                        .padding(.leading)
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(0..<12){_ in
                                CardView()
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .navigationTitle("Discover")
    }
}



#Preview {
    DiscoverView()
}
