import SwiftUI
import Lottie

struct NowShowingView: View {
    // MARK: - Environment & State
    @Environment(DataManager.self) private var data: DataManager
    @FocusState private var isCommentInputFocused: Bool
    @State private var animate = false
    
    @State private var error: Error? = nil
    @State private var isLoading = false
    @State private var collected = false
    @State private var liked = false
    @State private var disliked = false
    @State private var isReplying = false
    @State private var replyToComment: Comment? = nil
    private var movie: Movie? { data.currentClub?.movies.first }
    @State private var scrollToCommentId: String? = nil
    @State private var width = UIScreen.main.bounds.width
    @State private var usernameScale: CGFloat = 1.0
    @State private var triggerSuccessHaptic = false
    @State private var triggerHeavyImpact = false
    @State private var triggerMediumImpact = false
    @State private var triggerLightImpact = false
    
    // MARK: - Computed Properties
    private var progress: Double {
        guard let movie else { return 0 }
        
        let now = Date()
        let totalDuration = DateInterval(start: movie.startDate, end: movie.endDate).duration
        let elapsedDuration = DateInterval(start: movie.startDate, end: min(now, movie.endDate)).duration
        return elapsedDuration / totalDuration
    }
    
    // Format date to show correct day regardless of time zone
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date).uppercased()
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            if let movie {
                movieContent(movie)
                   
            } else {
                loadingView
            }
        }
        .overlay(animate ?
            LottieView(animation: .named("Falling-Confetti"))
            .playbackMode(.playing(.toProgress(2, loopMode: .playOnce)))
            .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))
            .offset(y: -250)
            .ignoresSafeArea() : nil
        )
        .onAppear {
            Task { await refreshClub() }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            if let error { Text(error.localizedDescription) }
        }
    }
    
    // MARK: - View Components
    @ViewBuilder
    private func movieContent(_ movie: Movie) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    FeaturedMovieView(collected: collected, movie: movie)
                    userInfoHeader(movie)
                    progressBar
                    CommentsView(onReply: handleReply)
                    
                    Color.clear
                        .frame(height: 1)
                        .id("bottomComment")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .onChange(of: movie.collectedBy) { updateCollectState() }
            .onChange(of: scrollToCommentId) {
                if scrollToCommentId != nil {
                    withAnimation {
                        proxy.scrollTo("bottomComment", anchor: .bottom)
                    }
                }
            }
        }
        
        if let movieId = movie.id {
            CommentInputView(
                movieId: movieId,
                replyToComment: $replyToComment,
                onCommentPosted: handleCommentPosted
            )
            .focused($isCommentInputFocused)
        }
    }
    
    private var loadingView: some View {
        WaveLoadingView()
            .refreshable {
                Task { await refreshClub() }
            }
    }
    
    private func userInfoHeader(_ movie: Movie) -> some View {
        ViewThatFits(in: .horizontal) {
            // Option 1: Full size
            standardHeaderContent(movie)
            
            // Option 2: Condensed with smaller font
            condensedHeaderContent(movie)
        }
    }
    
    private func standardHeaderContent(_ movie: Movie) -> some View {
        HStack(spacing: 8) {
            Label("\(movie.userName)", systemImage: "hand.point.up.left.fill")
                .font(.title)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut) {
                        collected = true
                        animate = true
                    }
                    performHapticSequence()
                    Task { await collectPoster() }
                } label: {
                    CollectButton(collected: $collected)
                }
                .sensoryFeedback(.success, trigger: triggerSuccessHaptic)
                .sensoryFeedback(.impact(weight: .heavy), trigger: triggerHeavyImpact)
                .sensoryFeedback(.impact(weight: .medium), trigger: triggerMediumImpact)
                .sensoryFeedback(.impact(weight: .light), trigger: triggerLightImpact)
                .sensoryFeedback(.impact(weight: .heavy), trigger: triggerHeavyImpact)
                .sensoryFeedback(.impact(weight: .medium), trigger: triggerMediumImpact)
                .sensoryFeedback(.impact(weight: .light), trigger: triggerLightImpact)
                
                ReviewThumbs(liked: $liked, disliked: $disliked)
            }
        }
        .padding(.trailing, 10)
    }
    
    private func condensedHeaderContent(_ movie: Movie) -> some View {
        HStack(spacing: 6) {
            Label("\(movie.userName)", systemImage: "hand.point.up.left.fill")
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
            
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut) {
                        collected = true
                        animate = true
                    }
                    performHapticSequence()
                    Task { await collectPoster() }
                } label: {
                    CollectButton(collected: $collected)
                        .scaleEffect(0.95)
                }
                .sensoryFeedback(.success, trigger: triggerSuccessHaptic)
                .sensoryFeedback(.impact(weight: .heavy), trigger: triggerHeavyImpact)
                .sensoryFeedback(.impact(weight: .medium), trigger: triggerMediumImpact)
                .sensoryFeedback(.impact(weight: .light), trigger: triggerLightImpact)
                
                ReviewThumbs(liked: $liked, disliked: $disliked)
                    .scaleEffect(0.95)
            }
        }
        .padding(.trailing, 8)
    }
    
    private var progressBar: some View {
        HStack {
            let _ = print("startDate: \(movie?.startDate)")
            Text(movie?.startDate != nil ? formatDate(movie!.startDate) : "")
                .font(.title3)
                .textCase(.uppercase)
            
            ProgressView(value: progress)
                .progressViewStyle(ClubProgressViewStyle())
                .frame(height: 10)
            
            Text(movie?.endDate != nil ? formatDate(movie!.endDate) : "")
                .font(.title3)
                .textCase(.uppercase)
        }
    }
    
    // MARK: - Helper Methods
    private func performHapticSequence() {
        // First play success feedback
        triggerSuccessHaptic.toggle()
        
        // Then play sequence of impacts with delays
        triggerHeavyImpact.toggle()
        
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            await MainActor.run {
                triggerMediumImpact.toggle()
            }
            
            try? await Task.sleep(for: .milliseconds(200))
            await MainActor.run {
                triggerLightImpact.toggle()
            }
        }
    }
    
    private func handleReply(_ comment: Comment) {
        replyToComment = comment
        isReplying = true
        isCommentInputFocused = true
    }
    
    private func handleCommentPosted() {
        scrollToCommentId = UUID().uuidString
    }
    
    private func updateCollectState() {
        guard
            let movie,
            let userId = data.currentUser?.id
        else { return }
        
        collected = movie.collectedBy.contains(userId)
        liked = movie.likedBy.contains(userId)
        disliked = movie.dislikedBy.contains(userId)
    }
    
    private func refreshClub() async {
        isLoading = true
        defer { isLoading = false }
        
        guard !data.clubId.isEmpty else { return }
        
        if let club = await data.fetchMovieClub(clubId: data.clubId) {
            data.currentClub = club
            updateCollectState()
        }
    }
    
    private func collectPoster() async {
        guard
            let movie,
            let movieId = movie.id,
            let clubName = data.currentClub?.name,
            let clubId = data.currentClub?.id,
            let userId = data.currentUser?.id
        else { return }
        
        let collectionItem = CollectionItem(
            movieId: movieId,
            imdbId: movie.imdbId,
            clubId: clubId,
            clubName: clubName,
            colorStr: ""
        )
        
        do {
            movie.collectedBy.append(userId)
            try await data.collectPoster(collectionItem: collectionItem)
        } catch {
            self.error = error
        }
    }
}

// MARK: - Progress View Style
struct ClubProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.5))
            
            if let fractionCompleted = configuration.fractionCompleted {
                Rectangle()
                    .foregroundColor(.white)
                    .frame(width: CGFloat(fractionCompleted) * 200)
            }
        }
        .padding(.horizontal)
    }
}
