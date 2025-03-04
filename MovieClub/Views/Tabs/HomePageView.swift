//
//  HomePageView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/7/24.
//

import SwiftUI
import FirebaseAuth


struct HomePageView: View {
    @Environment(DataManager.self) var data: DataManager
    @Binding var navPath: NavigationPath
    @Namespace private var namespace
    @State private var isLoading: Bool = true
    @State var userClubs: [MovieClub] = []
    // Animation states
    @State private var cardsAppeared = false
    @State private var cardOffsets: [CGFloat] = []
    @State private var cardOpacities: [Double] = []
    @State private var refreshTrigger = UUID() // Add refresh trigger
    @State private var initialLoadComplete = false // Track initial load
    @State private var animationStartTime: Date? = nil
    
    var sortedUserClubs: [MovieClub] {
        userClubs.sorted { club1, club2 in
            if let date1 = club1.createdAt, let date2 = club2.createdAt {
                return date1 < date2
            }
            return club1.createdAt != nil
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                WaveLoadingView()
            } else {
                // Original layout without extra padding/spacing changes
                if userClubs.isEmpty {
                    VStack {
                        Spacer()
                        Text("No clubs Found")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack {
                            ForEach(Array(sortedUserClubs.enumerated()), id: \.element.id) { index, movieClub in
                                NavigationLink(value: movieClub) {
                                    if #available(iOS 18.0, *) {
                                        MovieClubCardView(movieClub: movieClub)
                                            .padding(.vertical, 5)
                                            .matchedTransitionSource(id: movieClub.id, in: namespace)
                                            .offset(y: !initialLoadComplete ? (index < cardOffsets.count ? cardOffsets[index] : 50) : 0)
                                            .opacity(!initialLoadComplete ? (index < cardOpacities.count ? cardOpacities[index] : 0) : 1)
                                            .id("\(refreshTrigger)-\(movieClub.id ?? "")-\(movieClub.numMovies ?? 0)-\(movieClub.movies.first?.id ?? "none")")
                                    } else {
                                        MovieClubCardView(movieClub: movieClub)
                                            .padding(.vertical, 5)
                                            .offset(y: !initialLoadComplete ? (index < cardOffsets.count ? cardOffsets[index] : 50) : 0)
                                            .opacity(!initialLoadComplete ? (index < cardOpacities.count ? cardOpacities[index] : 0) : 1)
                                            .id("\(refreshTrigger)-\(movieClub.id ?? "")-\(movieClub.numMovies ?? 0)-\(movieClub.movies.first?.id ?? "none")")
                                    }
                                }
                            }
                        }
                        .navigationDestination(for: MovieClub.self) { club in
                            if #available(iOS 18.0, *) {
                                ClubDetailView(navPath: $navPath, club: club)
                                    .navigationTransition(.zoom(sourceID: club.id, in: namespace))
                                    .navigationTitle(club.name)
                                    .navigationBarTitleDisplayMode(.inline)
                            } else {
                                ClubDetailView(navPath: $navPath, club: club)
                                    .navigationTitle(club.name)
                                    .navigationBarTitleDisplayMode(.inline)
                            }
                        }
                    }
                    // Use TimelineView to track animation completion
                    .overlay {
                        if !initialLoadComplete && animationStartTime != nil {
                            TimelineView(.animation) { timeline in
                                Color.clear
                                    .onChange(of: timeline.date) {
                                        checkAnimationCompletion(currentTime: timeline.date)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: Path.newClub) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: Path.self) { route in
            switch route {
            case .newClub:
                NewClubView(path: $navPath)
            }
        }
        .navigationTitle("Movie Clubs")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            Task {
                if let userId = Auth.auth().currentUser?.uid {
                    // Only reset animation states if this is the initial load
                    if !initialLoadComplete {
                        cardOffsets = Array(repeating: 100, count: userClubs.count)
                        cardOpacities = Array(repeating: 0, count: userClubs.count)
                        cardsAppeared = false
                    }
                    
                    // Generate new refresh trigger to force view updates
                    refreshTrigger = UUID()
                    
                    // Fetch new data
                    self.userClubs = await data.fetchUserClubs(forUserId: userId)
                    data.userClubs = self.userClubs
                    
                    // Only animate if this is the initial load
                    if !initialLoadComplete {
                        initializeAnimationArrays()
                        animateCardsAppearance()
                    }
                }
            }
        }
        .onAppear {
            Task {
                if let userId = Auth.auth().currentUser?.uid {
                    // Generate new refresh trigger to force view updates
                    refreshTrigger = UUID()
                    
                    self.userClubs = await data.fetchUserClubs(forUserId: userId)
                    data.userClubs = self.userClubs
                    isLoading = false
                    
                    // Only initialize and animate if this is the first load
                    if !initialLoadComplete {
                        // Initialize animation arrays after clubs are loaded
                        initializeAnimationArrays()
                        // Start animation with a slight delay
                        animateCardsAppearance()
                    }
                }
            }
        }
    }
    
    // Initialize animation arrays based on number of clubs
    private func initializeAnimationArrays() {
        cardOffsets = Array(repeating: 100, count: sortedUserClubs.count)
        cardOpacities = Array(repeating: 0, count: sortedUserClubs.count)
    }
    
    // Animation function for staggered card appearance
    private func animateCardsAppearance() {
        // Set animation start time
        animationStartTime = Date()
        
        // Animate cards with staggered timing
        for i in 0..<cardOffsets.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.1)) {
                cardOffsets[i] = 0
                cardOpacities[i] = 1
            }
        }
        cardsAppeared = true
    }
    
    // Check if animation has completed based on elapsed time
    private func checkAnimationCompletion(currentTime: Date) {
        guard let startTime = animationStartTime, !initialLoadComplete else { return }
        
        // Calculate total animation duration (base animation time + delay for each card)
        let totalAnimationTime = 0.6 + (Double(cardOffsets.count) * 0.1)
        let elapsedTime = currentTime.timeIntervalSince(startTime)
        
        // If animation should be complete, update state
        if elapsedTime >= totalAnimationTime {
            initialLoadComplete = true
            animationStartTime = nil
        }
    }
}

enum Path: Hashable {
    case newClub
}
