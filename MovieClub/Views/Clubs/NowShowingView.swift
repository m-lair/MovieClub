//
//  NowPlayingView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI

struct NowShowingView: View {
    @Environment(DataManager.self) private var data: DataManager
    @State var isLoading: Bool = false
    @State var errorMessage: String = ""
    @State var collected: Bool = false
    @State var liked: Bool = false
    @State var disliked: Bool = false
    
    let movie: Movie
    var progress: Double {
        let now = Date()
        let totalDuration = DateInterval(start: movie.startDate, end: movie.endDate).duration
        let elapsedDuration = DateInterval(start: movie.startDate, end: min(now, movie.endDate)).duration
        
        return (elapsedDuration / totalDuration)
    }
    
    @State private var width = UIScreen.main.bounds.width
    var body: some View {
        VStack {
            ScrollView {
                FeaturedMovieView(collected: collected, movie: movie)
                    .task {
                        await getMovieDetails()
                    }
                HStack {
                    Label("\(movie.userName)", systemImage: "hand.point.up.left.fill")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    Spacer()
                    Button {
                        collected.toggle()
                        Task {
                            data.currentCollection.append(CollectionItem(url: "matrixPoster", color: .brown))
                        }
                    } label: {
                        CollectButton(collected: $collected)
                    }
                    
                    Button {
                        liked.toggle()
                    } label: {
                        Image(systemName: "hand.thumbsup.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(liked ? .green : .white)
                    }
                    
                    Button {
                        disliked.toggle()
                    } label: {
                        Image(systemName: "hand.thumbsdown.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(disliked ? .red : .white)
                    }
                }
                .padding(.trailing, 20)
                
                HStack {
                    Text(movie.startDate, format: .dateTime.day().month())
                        .font(.title3)
                        .textCase(.uppercase)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(ClubProgressViewStyle())
                        .frame(height: 10)
                    
                    Text(movie.endDate, format: .dateTime.day().month())
                        .font(.title3)
                        .textCase(.uppercase)
                    
                }
                CommentsView()
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            
            CommentInputView(movieId: movie.id ?? "")
            
        }
    }
    
    struct ClubProgressViewStyle: ProgressViewStyle {
        func makeBody(configuration: Configuration) -> some View {
            ZStack(alignment: .leading) {
                // Background rectangle (empty bar)
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.5))
                   
                
                // Foreground rectangle (filled bar based on progress)
                if let fractionCompleted = configuration.fractionCompleted {
                    Rectangle()
                        .foregroundColor(.white)
                        .frame(width: CGFloat(fractionCompleted) * 200) // Scale width based on fractionCompleted
                        
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func getMovieDetails() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let updatedMovie = try await data.fetchMovieDetails(for: movie)
            // Update the movie in DataManager
            data.movie = updatedMovie
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching movie details: \(error)")
        }
    }
}

