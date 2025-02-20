//
//  ArchiveRowView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/24/24.
//
import Foundation
import SwiftUI

struct ArchiveRowView: View {
    let movie: Movie

    var body: some View {
        HStack {
            // Left content (Text information)
            VStack(alignment: .leading) {
                Text(movie.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                HStack {
                    Text("Presented by:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(movie.userName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(movie.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("\(movie.endDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                    
                    }
                    Label {
                        Text("\(movie.likedBy.count)")
                    } icon: {
                        Image(systemName: "hand.thumbsup.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    .foregroundStyle(.green)
                    
                    Label {
                        Text("\(movie.dislikedBy.count)")
                    } icon: {
                        Image(systemName: "hand.thumbsdown.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    .foregroundStyle(.red)
                    
                    Label {
                        Text("\(movie.collectedBy.count)")
                    } icon: {
                        Image("collectIcon")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    .foregroundStyle(.yellow)

                }
            }
            .padding(.vertical)
            
            Spacer()
            
            CachedAsyncImage(url: URL(string: movie.poster), placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 150)
                    .overlay(Text("?"))
            })
            .frame(width: 100, height: 150)
            .cornerRadius(4)
            .shadow(radius: 4)
            
        }
        .padding()
        .background(Color.black)
    }
}



