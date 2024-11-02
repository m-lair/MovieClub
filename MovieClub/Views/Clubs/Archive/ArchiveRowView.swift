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
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("SEPT 04")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("SEPT 18")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("Presented by:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(movie.userName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical)
            
            Spacer()
            
            Image("matrixPoster")
                .resizable()
                .frame(width: 100, height: 150)
                .cornerRadius(4)
                .shadow(radius: 4)
            
        }
        .padding()
        .background(Color.black)
    }
}



