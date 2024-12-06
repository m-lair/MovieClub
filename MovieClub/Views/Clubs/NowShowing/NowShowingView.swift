//
//  NowShowingView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI

struct NowShowingView: View {
    @Environment(DataManager.self) private var data: DataManager
    @State var error: Error? = nil
    @State var isLoading: Bool = false
    @State var errorMessage: String = ""
    @State var collected: Bool = false
    @State var liked: Bool = false
    @State var disliked: Bool = false
    @State private var isReplying = false
    @State private var replyToComment: Comment? = nil
    @FocusState private var isCommentInputFocused: Bool
    @State var movie: Movie? = nil
    var progress: Double {
        let now = Date()
        if let movie {
            let totalDuration = DateInterval(start: movie.startDate, end: movie.endDate).duration
            let elapsedDuration = DateInterval(start: movie.startDate, end: min(now, movie.endDate)).duration
            return (elapsedDuration / totalDuration)
        }
        return 0
    }
    @State private var width = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
            if let movie {
                ScrollView {
                    FeaturedMovieView(collected: collected, movie: movie)
                    HStack {
                        Label("\(movie.userName)", systemImage: "hand.point.up.left.fill")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                        Spacer()
                        Button {
                            guard
                                let userId = data.currentUser?.id
                            else { return }
                            collected = true
                            self.movie?.collectedBy.append(userId)
                            Task {
                                await collectPoster()
                            }
                            collected = true
                        } label: {
                            CollectButton(collected: $collected)
                        }
                        
                        ReviewThumbs(liked: $liked, disliked: $disliked)
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
                .onChange(of: movie.collectedBy) {
                    updateCollectState()
                }
                .onAppear {
                    updateCollectState()
                }
                if let movieId = movie.id {
                    CommentInputView(movieId: movieId, replyToComment:  $replyToComment)
                        .focused($isCommentInputFocused)
                }

            } else {
                WaveLoadingView()
                    .refreshable {
                        Task {
                            await refreshClub()
                        }
                    }
            }
        }
        .onAppear() {
            Task {
                await refreshClub()
            }
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") {
                error = nil
            }
        }, message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        })
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
        if data.clubId.isEmpty { return }
        let club = await data.fetchMovieClub(clubId: data.clubId)
        if let club {
            data.currentClub = club
            movie = club.movies.first
            updateCollectState()
        }
    }
    
    private func updateCollectState() {
        guard
            let movie,
            let userId = data.currentUser?.id
        else { return }
        collected = movie.collectedBy.contains(userId)
    }
    
    func collectPoster() async {
        guard
            let movie,
            let movieId = movie.id,
            let clubName = data.currentClub?.name,
            let clubId = data.currentClub?.id
        else { return }
        
        
        let collectionItem = CollectionItem(id: movieId,  imdbId: movie.imdbId, clubId: clubId, clubName: clubName, colorStr: "green")
        do {
            try await data.collectPoster(collectionItem: collectionItem)
        } catch {
            self.error = error
            
        }
    }
}

