//
//  HomePageView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/7/24.
//

import SwiftUI

struct HomePageView: View {
    var movies: [Movie] = []
    
    var body: some View {
            NavigationView{
                List(movies){movie in
                    NavigationLink(destination: MovieDetailView(movie: movie)){
                        HStack{
                            MovieRow(movie: movie)
                            
                        }
                    }
                    
                }
                .navigationTitle("Movie Club")
            }
        }
        
    }



