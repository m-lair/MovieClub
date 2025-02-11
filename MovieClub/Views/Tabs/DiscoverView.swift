//
//  DiscoverView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//
import SwiftUI

import SwiftUI

struct DiscoverView: View {
    @Environment(DataManager.self) private var data
    
    // Local states to hold fetched content
    @State private var trendingClubs: [MovieClub] = []
    @State private var trendingMovies: [MovieAPIData] = []
    @State private var newsItems: [NewsItem] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // MARK: - Trending Clubs
                Group {
                    Text("Trending Clubs")
                        .font(.title)
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10){
                            ForEach(trendingClubs, id: \.id) { club in
                                MovieClubCardView(movieClub: club)
                                    .frame(width: 320, height: 200)
                                    .padding(.top)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
                
                // MARK: - Trending Movies
                Group {
                    Text("Trending Movies")
                        .font(.title)
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(trendingMovies, id: \.id) { movie in
                                MovieCardView(movieData: movie)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
                
                // MARK: - News
                Group {
                    Text("News")
                        .font(.title)
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(newsItems, id: \.id) { item in
                                NewsCardView(newsItem: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            Spacer()
        }
        .navigationTitle("Discover")
        // Async fetch of all “trending” data
        .task {
            do {
                trendingClubs   = try await data.fetchTrendingClubs()
                trendingMovies  = try await data.fetchTrendingMovies()
                newsItems       = try await data.fetchNewsItems()
            } catch {
                print("Error fetching discover data: \(error.localizedDescription)")
            }
        }
    }
}

struct MovieCardView: View {
    let movieData: MovieAPIData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let posterURL = URL(string: "https://image.tmdb.org/t/p/w500\(movieData.poster)")
                // Use AsyncImage or your own CachedAsyncImage
                AsyncImage(url: posterURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 120, height: 180)
            
            
            Text(movieData.title)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.green)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}


struct NewsItem: Identifiable, Codable {
    var id: String?
    var title: String
    var summary: String
    var date: Date
    // add other fields as needed
}

struct NewsCardView: View {
    let newsItem: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(newsItem.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(newsItem.summary)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.purple)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

