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
    @State private var isReplying = false
    @State private var replyToComment: Comment? = nil
    @FocusState private var isCommentInputFocused: Bool
    
    var movies: [Movie] { data.movies }
    var progress: Double {
        let now = Date()
        if let movie = movies.first {
            let totalDuration = DateInterval(start: movie.startDate, end: movie.endDate).duration
            let elapsedDuration = DateInterval(start: movie.startDate, end: min(now, movie.endDate)).duration
            return (elapsedDuration / totalDuration)
        }
        return 0
    }
    @State private var width = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
            if let movie = movies.first {
                ScrollView {
                    FeaturedMovieView(collected: collected, movie: movie)
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
                    CommentsView(onReply: { comment in
                        replyToComment = comment
                        isReplying = true
                        isCommentInputFocused = true
                    })
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
                if let movieId = movie.id {
                    CommentInputView(movieId: movieId, replyToComment:  $replyToComment)
                        .focused($isCommentInputFocused)
                }

            } else {
                Button("No Movies Coming Up") {
                    Task {
                        await refreshClub()
                    }
                }
                .foregroundStyle(.black)
                .buttonStyle(.borderedProminent)
            }
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
    func refreshClub() async {
        isLoading = true
        defer { isLoading = false }
        print("clubId: \(data.clubId)")
        await data.fetchMovieClub(clubId: data.clubId)
       
    }
}

